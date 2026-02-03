/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */

/* Mingw-w64 dwrite_3.h is broken
 *
 * We only need the definitions of one function and its dependencies.
 *   IDWriteFactory4::TranslateColorGlyphRun
 *
 * But we need to include all the prior functions in the same struct,
 * and parent structs, so that the functions are in the correct position
 * in the vtable. The parameters of the unused functions are not
 * required as we only need a function in the struct to create a
 * function pointer in the vtable.
 */

#ifndef DWRITE_EXTRA_H
#define DWRITE_EXTRA_H

#pragma GCC diagnostic ignored "-Wnon-virtual-dtor"

#include <dwrite_2.h>

interface IDWriteFactory3;
interface IDWriteFactory4;
interface IDWriteColorGlyphRunEnumerator1;

DEFINE_ENUM_FLAG_OPERATORS(DWRITE_GLYPH_IMAGE_FORMATS);

struct DWRITE_COLOR_GLYPH_RUN1 : DWRITE_COLOR_GLYPH_RUN
{
    DWRITE_GLYPH_IMAGE_FORMATS glyphImageFormat;
    DWRITE_MEASURING_MODE measuringMode;
};


DEFINE_GUID(IID_IDWriteColorGlyphRunEnumerator1, 0x7c5f86da, 0xc7a1, 0x4f05, 0xb8,0xe1, 0x55,0xa1,0x79,0xfe,0x5a,0x35);
MIDL_INTERFACE("7c5f86da-c7a1-4f05-b8e1-55a179fe5a35")
IDWriteColorGlyphRunEnumerator1 : public IDWriteColorGlyphRunEnumerator
{
    virtual HRESULT STDMETHODCALLTYPE GetCurrentRun(
        const DWRITE_COLOR_GLYPH_RUN1 **run) = 0;

};
__CRT_UUID_DECL(IDWriteColorGlyphRunEnumerator1, 0x7c5f86da, 0xc7a1, 0x4f05, 0xb8,0xe1, 0x55,0xa1,0x79,0xfe,0x5a,0x35)

DEFINE_GUID(IID_IDWriteFactory3, 0x9a1b41c3, 0xd3bb, 0x466a, 0x87,0xfc, 0xfe,0x67,0x55,0x6a,0x3b,0x65);
MIDL_INTERFACE("9a1b41c3-d3bb-466a-87fc-fe67556a3b65")
IDWriteFactory3 : public IDWriteFactory2
{
  virtual void STDMETHODCALLTYPE CreateGlyphRunAnalysis() = 0;
  virtual void STDMETHODCALLTYPE CreateCustomRenderingParams() = 0;
  virtual void STDMETHODCALLTYPE CreateFontFaceReference() = 0;
  virtual void STDMETHODCALLTYPE CreateFontFaceReference2() = 0;
  virtual void STDMETHODCALLTYPE GetSystemFontSet() = 0;
  virtual void STDMETHODCALLTYPE CreateFontSetBuilder() = 0;
  virtual void STDMETHODCALLTYPE CreateFontCollectionFromFontSet() = 0;
  virtual void STDMETHODCALLTYPE GetSystemFontCollection() = 0;
  virtual void STDMETHODCALLTYPE GetFontDownloadQueue() = 0;
};
__CRT_UUID_DECL(IDWriteFactory3, 0x9a1b41c3, 0xd3bb, 0x466a, 0x87,0xfc, 0xfe,0x67,0x55,0x6a,0x3b,0x65)

DEFINE_GUID(IID_IDWriteFactory4, 0x4b0b5bd3, 0x0797, 0x4549, 0x8a,0xc5, 0xfe,0x91,0x5c,0xc5,0x38,0x56);
MIDL_INTERFACE("4b0b5bd3-0797-4549-8ac5-fe915cc53856")
IDWriteFactory4 : public IDWriteFactory3
{
  virtual HRESULT STDMETHODCALLTYPE TranslateColorGlyphRun(
    D2D1_POINT_2F                      baselineOrigin,
    DWRITE_GLYPH_RUN const             *glyphRun,
    DWRITE_GLYPH_RUN_DESCRIPTION const *glyphRunDescription,
    DWRITE_GLYPH_IMAGE_FORMATS         desiredGlyphImageFormats,
    DWRITE_MEASURING_MODE              measuringMode,
    DWRITE_MATRIX const                *worldAndDpiTransform,
    UINT32                             colorPaletteIndex,
    IDWriteColorGlyphRunEnumerator1    **colorLayers) = 0;
};
__CRT_UUID_DECL(IDWriteFactory4, 0x4b0b5bd3, 0x0797, 0x4549, 0x8a,0xc5, 0xfe,0x91,0x5c,0xc5,0x38,0x56)


#endif /* DWRITE_EXTRA_H */
