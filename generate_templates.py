#!/usr/bin/env python3
"""
Generate 64x64 grayscale PNG template images for LetterQuest.

Stroke paths are ported directly from StrokeTemplate.swift. The images are
placed in LetterQuest/Assets.xcassets as individual imageset entries, matching
the name pattern template_<CHAR> expected by Letter.templateImageName.
"""

import math
import os
import struct
import zlib
import json

SIZE = 64
MARGIN = 6          # pixels from edge to drawing zone boundary
STROKE_RADIUS = 2.5 # pixels; controls stroke thickness

pi = math.pi


# ── Path-building primitives (mirrors StrokeTemplate.swift) ──────────────────

def line_pts(p0, p1, steps=10):
    return [(p0[0] + (p1[0]-p0[0])*i/steps,
             p0[1] + (p1[1]-p0[1])*i/steps) for i in range(steps+1)]


def bezier_pts(p0, c, p1, steps=16):
    result = []
    for i in range(steps+1):
        t = i / steps
        omt = 1 - t
        result.append((omt*omt*p0[0] + 2*omt*t*c[0] + t*t*p1[0],
                       omt*omt*p0[1] + 2*omt*t*c[1] + t*t*p1[1]))
    return result


def curve_through(p0, peak, p1, steps=16):
    """Quadratic Bézier that passes exactly through 'peak' at t=0.5."""
    cx = 2*peak[0] - 0.5*(p0[0]+p1[0])
    cy = 2*peak[1] - 0.5*(p0[1]+p1[1])
    return bezier_pts(p0, (cx, cy), p1, steps)


def elliptic_arc(cx, cy, rx, ry, a0, a1, steps=20):
    return [(cx + rx*math.cos(a0 + (a1-a0)*i/steps),
             cy + ry*math.sin(a0 + (a1-a0)*i/steps)) for i in range(steps+1)]


def circle_arc(cx, cy, r, a0, a1, steps=20):
    return elliptic_arc(cx, cy, r, r, a0, a1, steps)


# ── Per-letter stroke definitions ─────────────────────────────────────────────

def all_letter_strokes():
    return {
        'A': [
            line_pts((0.5, 0.05), (0.95, 0.95)),
            line_pts((0.5, 0.05), (0.05, 0.95)),
            line_pts((0.2, 0.60), (0.80, 0.60)),
        ],
        'B': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            (elliptic_arc(0.15, 0.275, 0.55, 0.225, -pi/2, pi/2) +
             elliptic_arc(0.15, 0.725, 0.65, 0.225, -pi/2, pi/2)[1:]),
        ],
        'C': [
            circle_arc(0.5, 0.5, 0.45, -pi/3, -5*pi/3),
        ],
        'D': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            elliptic_arc(0.15, 0.5, 0.75, 0.45, -pi/2, pi/2),
        ],
        'E': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.05), (0.85, 0.05)),
            line_pts((0.15, 0.50), (0.70, 0.50)),
            line_pts((0.15, 0.95), (0.85, 0.95)),
        ],
        'F': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.05), (0.85, 0.05)),
            line_pts((0.15, 0.50), (0.70, 0.50)),
        ],
        'G': [
            circle_arc(0.5, 0.5, 0.45, -pi/3, -5*pi/3),
            line_pts((0.45, 0.55), (0.85, 0.55)),
            line_pts((0.85, 0.55), (0.85, 0.85)),
        ],
        'H': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.85, 0.05), (0.85, 0.95)),
            line_pts((0.15, 0.50), (0.85, 0.50)),
        ],
        'I': [
            line_pts((0.5, 0.05), (0.5, 0.95)),
        ],
        'J': [
            line_pts((0.7, 0.05), (0.7, 0.70)),
            curve_through((0.7, 0.70), (0.45, 0.97), (0.2, 0.85)),
        ],
        'K': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.85, 0.05), (0.15, 0.50)),
            line_pts((0.15, 0.50), (0.85, 0.95)),
        ],
        'L': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.95), (0.85, 0.95)),
        ],
        'M': [
            line_pts((0.10, 0.05), (0.10, 0.95)),
            line_pts((0.10, 0.05), (0.50, 0.70)),
            line_pts((0.50, 0.70), (0.90, 0.05)),
            line_pts((0.90, 0.05), (0.90, 0.95)),
        ],
        'N': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.05), (0.85, 0.95)),
            line_pts((0.85, 0.05), (0.85, 0.95)),
        ],
        'O': [
            circle_arc(0.5, 0.5, 0.45, -pi/2, 3*pi/2),
        ],
        'P': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            elliptic_arc(0.15, 0.30, 0.60, 0.25, -pi/2, pi/2),
        ],
        'Q': [
            circle_arc(0.5, 0.5, 0.40, -pi/2, 3*pi/2),
            line_pts((0.60, 0.70), (0.95, 0.98)),
        ],
        'R': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            elliptic_arc(0.15, 0.30, 0.60, 0.25, -pi/2, pi/2),
            line_pts((0.15, 0.55), (0.85, 0.95)),
        ],
        'S': [
            (bezier_pts((0.85, 0.10), (0.05, 0.00), (0.50, 0.50)) +
             bezier_pts((0.50, 0.50), (0.95, 1.00), (0.15, 0.90))[1:]),
        ],
        'T': [
            line_pts((0.10, 0.05), (0.90, 0.05)),
            line_pts((0.50, 0.05), (0.50, 0.95)),
        ],
        'U': [
            (line_pts((0.10, 0.05), (0.10, 0.70), 6) +
             curve_through((0.10, 0.70), (0.50, 0.97), (0.90, 0.70))[1:] +
             line_pts((0.90, 0.70), (0.90, 0.05), 6)[1:]),
        ],
        'V': [
            line_pts((0.10, 0.05), (0.50, 0.95)),
            line_pts((0.50, 0.95), (0.90, 0.05)),
        ],
        'W': [
            line_pts((0.05, 0.05), (0.30, 0.95)),
            line_pts((0.30, 0.95), (0.50, 0.40)),
            line_pts((0.50, 0.40), (0.70, 0.95)),
            line_pts((0.70, 0.95), (0.95, 0.05)),
        ],
        'X': [
            line_pts((0.10, 0.05), (0.90, 0.95)),
            line_pts((0.90, 0.05), (0.10, 0.95)),
        ],
        'Y': [
            line_pts((0.10, 0.05), (0.50, 0.50)),
            line_pts((0.50, 0.50), (0.90, 0.05)),
            line_pts((0.50, 0.50), (0.50, 0.95)),
        ],
        'Z': [
            line_pts((0.10, 0.05), (0.90, 0.05)),
            line_pts((0.90, 0.05), (0.10, 0.95)),
            line_pts((0.10, 0.95), (0.90, 0.95)),
        ],
    }


# ── Rasteriser ────────────────────────────────────────────────────────────────

def dist_sq_to_segment(px, py, ax, ay, bx, by):
    """Squared distance from (px,py) to segment (ax,ay)-(bx,by)."""
    dx, dy = bx - ax, by - ay
    len_sq = dx*dx + dy*dy
    if len_sq < 1e-10:
        return (px-ax)**2 + (py-ay)**2
    t = max(0.0, min(1.0, ((px-ax)*dx + (py-ay)*dy) / len_sq))
    return (px - (ax + t*dx))**2 + (py - (ay + t*dy))**2


def render_letter(strokes, size, margin, stroke_radius):
    """Render normalised strokes onto a size×size float pixel array (0=black, 1=white)."""
    pixels = [[1.0] * size for _ in range(size)]
    draw_w = size - 2 * margin

    for stroke in strokes:
        pix = [(margin + x * draw_w, margin + y * draw_w) for x, y in stroke]
        for i in range(len(pix) - 1):
            ax, ay = pix[i]
            bx, by = pix[i + 1]
            min_x = max(0, int(min(ax, bx) - stroke_radius - 1))
            max_x = min(size - 1, int(max(ax, bx) + stroke_radius + 1))
            min_y = max(0, int(min(ay, by) - stroke_radius - 1))
            max_y = min(size - 1, int(max(ay, by) + stroke_radius + 1))

            for py in range(min_y, max_y + 1):
                for px in range(min_x, max_x + 1):
                    dist = math.sqrt(dist_sq_to_segment(px, py, ax, ay, bx, by))
                    # Signed-distance anti-aliasing: 0.5px feather
                    coverage = max(0.0, min(1.0, stroke_radius - dist + 0.5))
                    # Darken toward black; multiple strokes take the darkest value
                    pixels[py][px] = min(pixels[py][px], 1.0 - coverage)

    return pixels


# ── PNG encoder (no external dependencies) ───────────────────────────────────

def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)


def encode_png(pixels, size) -> bytes:
    """Encode a float pixel array as an 8-bit grayscale PNG."""
    ihdr = _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 0, 0, 0, 0))
    raw = b''.join(
        b'\x00' + bytes(max(0, min(255, int(pixels[y][x] * 255))) for x in range(size))
        for y in range(size)
    )
    idat = _chunk(b'IDAT', zlib.compress(raw, 9))
    iend = _chunk(b'IEND', b'')
    return b'\x89PNG\r\n\x1a\n' + ihdr + idat + iend


# ── Asset catalog builder ─────────────────────────────────────────────────────

def write_json(path, obj):
    with open(path, 'w') as f:
        json.dump(obj, f, indent=2)
        f.write('\n')


def main():
    root = os.path.dirname(os.path.abspath(__file__))
    xcassets = os.path.join(root, 'LetterQuest', 'Assets.xcassets')
    os.makedirs(xcassets, exist_ok=True)

    write_json(os.path.join(xcassets, 'Contents.json'), {
        'info': {'author': 'xcode', 'version': 1}
    })

    strokes_by_letter = all_letter_strokes()

    for char in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
        pixels = render_letter(strokes_by_letter[char], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)

        name = f'template_{char}'
        imageset_dir = os.path.join(xcassets, f'{name}.imageset')
        os.makedirs(imageset_dir, exist_ok=True)

        with open(os.path.join(imageset_dir, f'{name}.png'), 'wb') as f:
            f.write(png)

        write_json(os.path.join(imageset_dir, 'Contents.json'), {
            'images': [{
                'filename': f'{name}.png',
                'idiom': 'universal',
                'scale': '1x',
            }],
            'info': {'author': 'xcode', 'version': 1},
            'properties': {'template-rendering-intent': 'original'},
        })

        print(f'  {name}.png')

    print(f'\nAsset catalog written to:\n  {xcassets}')


if __name__ == '__main__':
    main()
