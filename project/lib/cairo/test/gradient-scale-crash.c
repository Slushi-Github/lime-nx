/*
 * Copyright © 2024 Koichi Akabe
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Author: Koichi Akabe <vbkaisetsu@gmail.com>
 */

#include "cairo-test.h"

static cairo_test_status_t
draw (cairo_t *cr, int width, int height)
{
    cairo_pattern_t *p = cairo_pattern_create_linear (0, 0, 0, 100);

    cairo_pattern_add_color_stop_rgb (p, 0, 1, 1, 1);
    cairo_pattern_add_color_stop_rgb (p, 1, 1, 0, 0);

    cairo_matrix_t m;
    cairo_matrix_init (&m, 100000, 0, 0, 100000, 0, 0);
    cairo_pattern_set_matrix (p, &m);

    cairo_set_source (cr, p);
    cairo_rectangle (cr, 0, 0, 100, 100);
    cairo_paint (cr);

    cairo_pattern_destroy (p);

    return CAIRO_TEST_SUCCESS;
}

CAIRO_TEST (gradient_scale_crash,
	    "Verify fix for https://gitlab.freedesktop.org/cairo/cairo/-/issues/789",
	    "gradient, pattern", /* keywords */
	    NULL, /* requirements */
	    0, 0,
	    NULL, draw)
