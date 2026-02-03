/* -*- Mode: c; tab-width: 8; c-basic-offset: 4; indent-tabs-mode: t; -*- */
/* Cairo - a vector graphics library with display and print output
 *
 * Copyright © 2010 Mozilla Foundation
 *
 * This library is free software; you can redistribute it and/or
 * modify it either under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 * (the "LGPL") or, at your option, under the terms of the Mozilla
 * Public License Version 1.1 (the "MPL"). If you do not alter this
 * notice, a recipient may use your version of this file under either
 * the MPL or the LGPL.
 *
 * You should have received a copy of the LGPL along with this library
 * in the file COPYING-LGPL-2.1; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 * You should have received a copy of the MPL along with this library
 * in the file COPYING-MPL-1.1
 *
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY
 * OF ANY KIND, either express or implied. See the LGPL or the MPL for
 * the specific language governing rights and limitations.
 *
 * The Original Code is the cairo graphics library.
 *
 * The Initial Developer of the Original Code is the Mozilla Foundation
 *
 * Contributor(s):
 *	Bas Schouten <bschouten@mozilla.com>
 */

#include "cairoint.h"
#include <dwrite.h>
#include <d2d1.h>

/* If either of the dwrite_2.h or d2d1_3.h headers required for color fonts
 * is not available, include our own version containing just the functions we need.
 */

#if HAVE_DWRITE_3_H
#include <dwrite_3.h>
#else
#include "dw-extra.h"
#endif

#if HAVE_D2D1_3_H
#include <d2d1_3.h>
#else
#include "d2d1-extra.h"
#endif


// DirectWrite is not available on all platforms.
typedef HRESULT (WINAPI*DWriteCreateFactoryFunc)(
  DWRITE_FACTORY_TYPE factoryType,
  REFIID iid,
  IUnknown **factory
);

/* #cairo_scaled_font_t implementation */
struct _cairo_dwrite_scaled_font {
    cairo_scaled_font_t base;
    cairo_matrix_t mat;
    cairo_matrix_t mat_inverse;
    cairo_antialias_t antialias_mode;
    DWRITE_MEASURING_MODE measuring_mode;
    enum TextRenderingState {
        TEXT_RENDERING_UNINITIALIZED,
        TEXT_RENDERING_NO_CLEARTYPE,
        TEXT_RENDERING_NORMAL,
        TEXT_RENDERING_GDI_CLASSIC
    };
    TextRenderingState rendering_mode;
};
typedef struct _cairo_dwrite_scaled_font cairo_dwrite_scaled_font_t;

class DWriteFactory
{
public:
    static IDWriteFactory *Instance()
    {
	if (!mFactoryInstance) {
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-function-type"
#endif
	    DWriteCreateFactoryFunc createDWriteFactory = (DWriteCreateFactoryFunc)
		GetProcAddress(LoadLibraryW(L"dwrite.dll"), "DWriteCreateFactory");
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
	    if (createDWriteFactory) {
		HRESULT hr = createDWriteFactory(
		    DWRITE_FACTORY_TYPE_SHARED,
		    __uuidof(IDWriteFactory),
		    reinterpret_cast<IUnknown**>(&mFactoryInstance));
		assert(SUCCEEDED(hr));
	    }
	}
	return mFactoryInstance;
    }

    static IDWriteFactory4 *Instance4()
    {
	if (!mFactoryInstance4) {
	    if (Instance()) {
		Instance()->QueryInterface(&mFactoryInstance4);
	    }
	}
	return mFactoryInstance4;
    }

    static IDWriteFontCollection *SystemCollection()
    {
	if (!mSystemCollection) {
	    if (Instance()) {
		HRESULT hr = Instance()->GetSystemFontCollection(&mSystemCollection);
		assert(SUCCEEDED(hr));
	    }
	}
	return mSystemCollection;
    }

    static IDWriteFontFamily *FindSystemFontFamily(const WCHAR *aFamilyName)
    {
	UINT32 idx;
	BOOL found;
	if (!SystemCollection()) {
	    return NULL;
	}
	SystemCollection()->FindFamilyName(aFamilyName, &idx, &found);
	if (!found) {
	    return NULL;
	}

	IDWriteFontFamily *family;
	SystemCollection()->GetFontFamily(idx, &family);
	return family;
    }

    static IDWriteRenderingParams *RenderingParams(cairo_dwrite_scaled_font_t::TextRenderingState mode)
    {
	if (!mDefaultRenderingParams ||
            !mForceGDIClassicRenderingParams ||
            !mCustomClearTypeRenderingParams)
        {
	    CreateRenderingParams();
	}
	IDWriteRenderingParams *params;
        if (mode == cairo_dwrite_scaled_font_t::TEXT_RENDERING_NO_CLEARTYPE) {
            params = mDefaultRenderingParams;
        } else if (mode == cairo_dwrite_scaled_font_t::TEXT_RENDERING_GDI_CLASSIC && mRenderingMode < 0) {
            params = mForceGDIClassicRenderingParams;
        } else {
            params = mCustomClearTypeRenderingParams;
        }
	if (params) {
	    params->AddRef();
	}
	return params;
    }

    static void SetRenderingParams(FLOAT aGamma,
				   FLOAT aEnhancedContrast,
				   FLOAT aClearTypeLevel,
				   int aPixelGeometry,
				   int aRenderingMode)
    {
	mGamma = aGamma;
	mEnhancedContrast = aEnhancedContrast;
	mClearTypeLevel = aClearTypeLevel;
        mPixelGeometry = aPixelGeometry;
        mRenderingMode = aRenderingMode;
	// discard any current RenderingParams objects
	if (mCustomClearTypeRenderingParams) {
	    mCustomClearTypeRenderingParams->Release();
	    mCustomClearTypeRenderingParams = NULL;
	}
	if (mForceGDIClassicRenderingParams) {
	    mForceGDIClassicRenderingParams->Release();
	    mForceGDIClassicRenderingParams = NULL;
	}
	if (mDefaultRenderingParams) {
	    mDefaultRenderingParams->Release();
	    mDefaultRenderingParams = NULL;
	}
    }

    static int GetClearTypeRenderingMode() {
        return mRenderingMode;
    }

private:
    static void CreateRenderingParams();

    static IDWriteFactory *mFactoryInstance;
    static IDWriteFactory4 *mFactoryInstance4;
    static IDWriteFontCollection *mSystemCollection;
    static IDWriteRenderingParams *mDefaultRenderingParams;
    static IDWriteRenderingParams *mCustomClearTypeRenderingParams;
    static IDWriteRenderingParams *mForceGDIClassicRenderingParams;
    static FLOAT mGamma;
    static FLOAT mEnhancedContrast;
    static FLOAT mClearTypeLevel;
    static int mPixelGeometry;
    static int mRenderingMode;
};

class AutoDWriteGlyphRun : public DWRITE_GLYPH_RUN
{
    static const int kNumAutoGlyphs = 256;

public:
    AutoDWriteGlyphRun() {
        glyphCount = 0;
    }

    ~AutoDWriteGlyphRun() {
        if (glyphCount > kNumAutoGlyphs) {
            delete[] glyphIndices;
            delete[] glyphAdvances;
            delete[] glyphOffsets;
        }
    }

    void allocate(int aNumGlyphs) {
        glyphCount = aNumGlyphs;
        if (aNumGlyphs <= kNumAutoGlyphs) {
            glyphIndices = &mAutoIndices[0];
            glyphAdvances = &mAutoAdvances[0];
            glyphOffsets = &mAutoOffsets[0];
        } else {
            glyphIndices = new UINT16[aNumGlyphs];
            glyphAdvances = new FLOAT[aNumGlyphs];
            glyphOffsets = new DWRITE_GLYPH_OFFSET[aNumGlyphs];
        }
    }

private:
    DWRITE_GLYPH_OFFSET mAutoOffsets[kNumAutoGlyphs];
    FLOAT               mAutoAdvances[kNumAutoGlyphs];
    UINT16              mAutoIndices[kNumAutoGlyphs];
};

/* #cairo_font_face_t implementation */
struct _cairo_dwrite_font_face {
    cairo_font_face_t base;
    IDWriteFontFace *dwriteface;
    cairo_bool_t have_color;
};
typedef struct _cairo_dwrite_font_face cairo_dwrite_font_face_t;

DWRITE_MATRIX _cairo_dwrite_matrix_from_matrix(const cairo_matrix_t *matrix);

// This will initialize a DWrite glyph run from cairo glyphs and a scaled_font.
void
_cairo_dwrite_glyph_run_from_glyphs(cairo_glyph_t *glyphs,
				    int num_glyphs,
				    cairo_dwrite_scaled_font_t *scaled_font,
				    AutoDWriteGlyphRun *run,
				    cairo_bool_t *transformed);
