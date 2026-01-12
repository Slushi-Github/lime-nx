/*
 * Copyright © 2024 worldiety GmbH
 *
 * Permission to use, copy, modify, distribute, and sell this software
 * and its documentation for any purpose is hereby granted without
 * fee, provided that the above copyright notice appear in all copies
 * and that both that copyright notice and this permission notice
 * appear in supporting documentation, and that the name of
 * worldiety not be used in advertising or publicity pertaining to
 * distribution of the software without specific, written prior
 * permission. worldiety makes no representations about the
 * suitability of this software for any purpose.  It is provided "as
 * is" without express or implied warranty.
 *
 * WORLDIETY DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
 * SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS, IN NO EVENT SHALL WORLDIETY BE LIABLE FOR ANY SPECIAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
 * IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Author: Heiko Lewin <hlewin@worldiety.de>
 */
#include "cairo-test.h"

#define WIDTH  128
#define HEIGHT 64


static cairo_test_status_t
draw(cairo_t *cr, int width, int height) {
    cairo_glyph_t *glyphs = NULL;
    int num_glyphs = 0;
    cairo_path_t *path = NULL, *path2 = NULL;
    (void)width;
    (void)height;

    /* black on white color */
    cairo_set_source_rgb(cr, 1., 1., 1.);
    cairo_paint(cr);
    cairo_set_source_rgb(cr, 0, 0, 0);


    /* translate to some point well outside the surface */
    cairo_translate(cr, -width * 100, 0);

    /* create a simple path to illustrate the correct behaviour */
    cairo_rectangle(cr, 0, 0, width/2.0, 2);
    path = cairo_copy_path(cr);
    cairo_new_path(cr);

    /* create another path from glyphs - this is broken when clipping to early */
    {
        cairo_set_font_size(cr, 32);
        cairo_scaled_font_t *sf = cairo_get_scaled_font(cr);
        cairo_scaled_font_text_to_glyphs(sf, 0, 0, "Test", 4, &glyphs, &num_glyphs, 0, 0, 0);
        cairo_glyph_path(cr, glyphs, num_glyphs);
        path2 = cairo_copy_path(cr);
    }

    /* translate to a visible point and draw both paths */
    cairo_identity_matrix(cr);
    cairo_translate(cr, width/4.0, 48);

    cairo_append_path(cr, path);
    cairo_append_path(cr, path2);
    cairo_fill(cr);

    cairo_path_destroy(path);
    cairo_path_destroy(path2);
    free(glyphs);

    return CAIRO_TEST_SUCCESS;
}

CAIRO_TEST (glyph_path,
            "Tests cairo_glyph_path",
            "text, glyph, path", /* keywords */
            "target=raster", /* should be enough */
            WIDTH, HEIGHT,
            NULL, draw)
