/* -*- Mode: c; tab-width: 8; c-basic-offset: 4; indent-tabs-mode: t; -*- */
/* Cairo - a vector graphics library with display and print output
 *
 * Copyright © 2022 Adrian Johnson
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
 * The Initial Developer of the Original Code is Adrian Johnson
 *
 * Contributor(s):
 *	Adrian Johnson <ajohnson@redneon.com>
 */


/* gtkdoc won't scan .cpp files so we wrap the public API in cairo-dwrite-font.cpp
 * with this .c wrapper containing the gtkdocs for cairo-dwrite-font.cpp.
 */

#include "cairo-win32-private.h"

/**
 * SECTION:cairo-dwrite-fonts
 * @Title: DWrite Fonts
 * @Short_Description: Font support for Microsoft DWrite
 * @See_Also: #cairo_font_face_t
 *
 * The Microsoft DWrite font backend is primarily used to render text on
 * Microsoft Windows systems.
 **/

/**
 * CAIRO_HAS_DWRITE_FONT:
 *
 * Defined if the Microsoft DWrite font backend is available.
 * This macro can be used to conditionally compile backend-specific code.
 *
 * Since: 1.18
 **/

/**
 * cairo_dwrite_font_face_create_for_dwrite_fontface:
 * @dwrite_font_face: A pointer to an #IDWriteFontFace specifying the
 * DWrite font to use.
 *
 * Creates a new font for the DWrite font backend based on a
 * DWrite font face. This font can then be used with
 * cairo_set_font_face() or cairo_scaled_font_create().

 * Here is an example of how this function might be used:
 * <informalexample><programlisting><![CDATA[
 * #include <cairo-win32.h>
 * #include <dwrite.h>
 *
 * IDWriteFactory* dWriteFactory = NULL;
 * HRESULT hr = DWriteCreateFactory(
 *     DWRITE_FACTORY_TYPE_SHARED,
 *     __uuidof(IDWriteFactory),
 *    reinterpret_cast<IUnknown**>(&dWriteFactory));
 *
 * IDWriteFontCollection *systemCollection;
 * hr = dWriteFactory->GetSystemFontCollection(&systemCollection);
 *
 * UINT32 idx;
 * BOOL found;
 * systemCollection->FindFamilyName(L"Segoe UI Emoji", &idx, &found);
 *
 * IDWriteFontFamily *family;
 * systemCollection->GetFontFamily(idx, &family);
 *
 * IDWriteFont *dwritefont;
 * DWRITE_FONT_WEIGHT weight = DWRITE_FONT_WEIGHT_NORMAL;
 * DWRITE_FONT_STYLE style = DWRITE_FONT_STYLE_NORMAL;
 * hr = family->GetFirstMatchingFont(weight, DWRITE_FONT_STRETCH_NORMAL, style, &dwritefont);
 *
 * IDWriteFontFace *dwriteface;
 * hr = dwritefont->CreateFontFace(&dwriteface);
 *
 * cairo_font_face_t *face;
 * face = cairo_dwrite_font_face_create_for_dwrite_fontface(dwriteface);
 * cairo_set_font_face(cr, face);
 * cairo_set_font_size(cr, 70);
 * cairo_move_to(cr, 100, 100);
 * cairo_show_text(cr, "😃");
 * ]]></programlisting></informalexample>
 *
 * Return value: a newly created #cairo_font_face_t. Free with
 *  cairo_font_face_destroy() when you are done using it.
 *
 * Since: 1.18
 **/
cairo_font_face_t*
cairo_dwrite_font_face_create_for_dwrite_fontface (void *dwrite_font_face)
{
    return cairo_dwrite_font_face_create_for_dwrite_fontface_internal (dwrite_font_face);
}
