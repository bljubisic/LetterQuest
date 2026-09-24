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

def lowercase_letter_strokes():
    # Body zone: y 0.20–0.85 (same physical scale as uppercase).
    # Ascenders extend to y 0.05. Descenders reach y ~0.95.
    return {
        'a': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.85)),
        ],
        'b': [
            line_pts((0.18, 0.05), (0.18, 0.85)),
            elliptic_arc(0.18, 0.57, 0.62, 0.28, -pi/2, pi/2),
        ],
        'c': [
            circle_arc(0.5, 0.50, 0.38, -pi/3, -5*pi/3),
        ],
        'd': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.05), (0.72, 0.85)),
        ],
        'e': [
            line_pts((0.12, 0.50), (0.88, 0.50)),
            circle_arc(0.5, 0.50, 0.38, 0, -5*pi/3),
        ],
        'f': [
            (curve_through((0.62, 0.10), (0.28, 0.04), (0.40, 0.20)) +
             line_pts((0.40, 0.20), (0.40, 0.85), 6)[1:]),
            line_pts((0.18, 0.32), (0.64, 0.32)),
        ],
        'g': [
            circle_arc(0.42, 0.50, 0.35, -pi/2, 3*pi/2),
            (line_pts((0.77, 0.15), (0.77, 0.90), 6) +
             curve_through((0.77, 0.90), (0.55, 0.97), (0.25, 0.92))[1:]),
        ],
        'h': [
            line_pts((0.18, 0.05), (0.18, 0.85)),
            (curve_through((0.18, 0.45), (0.50, 0.22), (0.80, 0.45)) +
             line_pts((0.80, 0.45), (0.80, 0.85), 5)[1:]),
        ],
        'i': [
            line_pts((0.5, 0.22), (0.5, 0.85)),
            line_pts((0.44, 0.10), (0.56, 0.14), 3),
        ],
        'j': [
            (line_pts((0.55, 0.22), (0.55, 0.90), 5) +
             curve_through((0.55, 0.90), (0.38, 0.97), (0.22, 0.90))[1:]),
            line_pts((0.49, 0.10), (0.61, 0.14), 3),
        ],
        'k': [
            line_pts((0.18, 0.05), (0.18, 0.85)),
            line_pts((0.80, 0.22), (0.18, 0.53)),
            line_pts((0.18, 0.53), (0.80, 0.85)),
        ],
        'l': [
            line_pts((0.5, 0.05), (0.5, 0.85)),
        ],
        'm': [
            line_pts((0.08, 0.15), (0.08, 0.88)),
            (curve_through((0.08, 0.44), (0.30, 0.15), (0.50, 0.44)) +
             line_pts((0.50, 0.44), (0.50, 0.88), 4)[1:]),
            (curve_through((0.50, 0.44), (0.72, 0.15), (0.92, 0.44)) +
             line_pts((0.92, 0.44), (0.92, 0.88), 4)[1:]),
        ],
        'n': [
            line_pts((0.18, 0.22), (0.18, 0.85)),
            (curve_through((0.18, 0.47), (0.50, 0.22), (0.80, 0.47)) +
             line_pts((0.80, 0.47), (0.80, 0.85), 5)[1:]),
        ],
        'o': [
            circle_arc(0.5, 0.50, 0.38, -pi/2, 3*pi/2),
        ],
        'p': [
            line_pts((0.18, 0.18), (0.18, 0.95)),
            elliptic_arc(0.18, 0.52, 0.62, 0.30, -pi/2, pi/2),
        ],
        'q': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.95)),
        ],
        'r': [
            line_pts((0.22, 0.22), (0.22, 0.85)),
            curve_through((0.22, 0.42), (0.52, 0.22), (0.76, 0.38)),
        ],
        's': [
            (curve_through((0.80, 0.15), (0.15, 0.35), (0.50, 0.52)) +
             curve_through((0.50, 0.52), (0.85, 0.68), (0.20, 0.88))[1:]),
        ],
        't': [
            line_pts((0.5, 0.05), (0.5, 0.85)),
            line_pts((0.18, 0.30), (0.78, 0.30)),
        ],
        'u': [
            (line_pts((0.12, 0.15), (0.12, 0.65), 4) +
             curve_through((0.12, 0.65), (0.5, 0.92), (0.88, 0.65))[1:] +
             line_pts((0.88, 0.65), (0.88, 0.15), 4)[1:]),
        ],
        'v': [
            line_pts((0.12, 0.20), (0.5, 0.85)),
            line_pts((0.5, 0.85), (0.88, 0.20)),
        ],
        'w': [
            line_pts((0.05, 0.20), (0.27, 0.85)),
            line_pts((0.27, 0.85), (0.50, 0.50)),
            line_pts((0.50, 0.50), (0.73, 0.85)),
            line_pts((0.73, 0.85), (0.95, 0.20)),
        ],
        'x': [
            line_pts((0.12, 0.20), (0.88, 0.85)),
            line_pts((0.88, 0.20), (0.12, 0.85)),
        ],
        'y': [
            line_pts((0.12, 0.20), (0.52, 0.62)),
            (line_pts((0.88, 0.20), (0.52, 0.62), 4) +
             line_pts((0.52, 0.62), (0.52, 0.88), 3)[1:] +
             curve_through((0.52, 0.88), (0.36, 0.97), (0.20, 0.90))[1:]),
        ],
        'z': [
            line_pts((0.10, 0.12), (0.90, 0.12)),
            line_pts((0.90, 0.12), (0.10, 0.88)),
            line_pts((0.10, 0.88), (0.90, 0.88)),
        ],
    }


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
            line_pts((0.50, 0.05), (0.50, 0.95)),
            line_pts((0.10, 0.05), (0.90, 0.05)),
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


def cyrillic_uppercase_letter_strokes():
    # Cap box: x and y both 0.05-0.95, mirrors CyrillicStrokeDefinitions.swift.
    # Dict keys are the ASCII asset-name fragments from CyrillicAlphabet.swift
    # (not the Cyrillic characters themselves), since this script only needs
    # to know which strokes go with which output filename.
    return {
        'a': [
            line_pts((0.5, 0.05), (0.95, 0.95)),
            line_pts((0.5, 0.05), (0.05, 0.95)),
            line_pts((0.2, 0.6), (0.8, 0.6)),
        ],
        'b': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.05), (0.75, 0.05)),
            elliptic_arc(0.15, 0.65, 0.55, 0.3, -pi/2, pi/2),
        ],
        'v': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            (elliptic_arc(0.15, 0.275, 0.55, 0.225, -pi/2, pi/2) +
             elliptic_arc(0.15, 0.725, 0.65, 0.225, -pi/2, pi/2)[1:]),
        ],
        'g': [
            line_pts((0.15, 0.05), (0.85, 0.05)),
            line_pts((0.15, 0.05), (0.15, 0.95)),
        ],
        'd': [
            line_pts((0.15, 0.05), (0.85, 0.05)),
            (line_pts((0.15, 0.05), (0.15, 0.85)) + line_pts((0.15, 0.85), (0.05, 0.95))[1:]),
            (line_pts((0.85, 0.05), (0.85, 0.85)) + line_pts((0.85, 0.85), (0.95, 0.95))[1:]),
            line_pts((0.15, 0.85), (0.85, 0.85)),
        ],
        'dj': [
            line_pts((0.1, 0.05), (0.7, 0.05)),
            line_pts((0.4, 0.05), (0.4, 0.95)),
            (elliptic_arc(0.4, 0.75, 0.45, 0.2, -pi/2, 0) +
             line_pts((0.85, 0.75), (0.85, 0.8), 2)[1:] +
             curve_through((0.85, 0.8), (0.75, 0.98), (0.6, 0.9))[1:]),
        ],
        'e': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.05), (0.85, 0.05)),
            line_pts((0.15, 0.5), (0.7, 0.5)),
            line_pts((0.15, 0.95), (0.85, 0.95)),
        ],
        'zh': [
            line_pts((0.5, 0.05), (0.5, 0.95)),
            line_pts((0.08, 0.05), (0.5, 0.5)),
            line_pts((0.5, 0.5), (0.08, 0.95)),
            line_pts((0.92, 0.05), (0.5, 0.5)),
            line_pts((0.5, 0.5), (0.92, 0.95)),
        ],
        'z': [
            (elliptic_arc(0.4, 0.28, 0.45, 0.23, -pi/2, pi/2) +
             elliptic_arc(0.4, 0.72, 0.5, 0.23, -pi/2, pi/2)[1:]),
        ],
        'i': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.15, 0.95), (0.85, 0.05)),
            line_pts((0.85, 0.05), (0.85, 0.95)),
        ],
        'j': [
            line_pts((0.7, 0.05), (0.7, 0.70)),
            curve_through((0.7, 0.70), (0.45, 0.97), (0.2, 0.85)),
        ],
        'k': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.85, 0.05), (0.15, 0.50)),
            line_pts((0.15, 0.50), (0.85, 0.95)),
        ],
        'l': [
            line_pts((0.15, 0.95), (0.5, 0.05)),
            line_pts((0.5, 0.05), (0.85, 0.95)),
        ],
        'lj': [
            line_pts((0.25, 0.05), (0.6, 0.05)),
            (line_pts((0.25, 0.05), (0.25, 0.75), 6) + curve_through((0.25, 0.75), (0.15, 0.93), (0.05, 0.85))[1:]),
            line_pts((0.6, 0.05), (0.6, 0.95)),
            elliptic_arc(0.6, 0.72, 0.4, 0.23, -pi/2, pi/2),
        ],
        'm': [
            line_pts((0.1, 0.05), (0.1, 0.95)),
            line_pts((0.1, 0.05), (0.5, 0.70)),
            line_pts((0.5, 0.70), (0.9, 0.05)),
            line_pts((0.9, 0.05), (0.9, 0.95)),
        ],
        'n': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            line_pts((0.85, 0.05), (0.85, 0.95)),
            line_pts((0.15, 0.50), (0.85, 0.50)),
        ],
        'nj': [
            line_pts((0.1, 0.05), (0.1, 0.95)),
            line_pts((0.45, 0.05), (0.45, 0.95)),
            line_pts((0.1, 0.50), (0.45, 0.50)),
            elliptic_arc(0.45, 0.72, 0.45, 0.23, -pi/2, pi/2),
        ],
        'o': [
            circle_arc(0.5, 0.5, 0.45, -pi/2, 3*pi/2),
        ],
        'p': [
            line_pts((0.1, 0.05), (0.9, 0.05)),
            line_pts((0.1, 0.05), (0.1, 0.95)),
            line_pts((0.9, 0.05), (0.9, 0.95)),
        ],
        'r': [
            line_pts((0.15, 0.05), (0.15, 0.95)),
            elliptic_arc(0.15, 0.30, 0.6, 0.25, -pi/2, pi/2),
        ],
        's': [
            circle_arc(0.5, 0.5, 0.45, -pi/3, -5*pi/3),
        ],
        't': [
            line_pts((0.1, 0.05), (0.9, 0.05)),
            line_pts((0.5, 0.05), (0.5, 0.95)),
        ],
        'tj': [
            line_pts((0.1, 0.05), (0.7, 0.05)),
            line_pts((0.4, 0.05), (0.4, 0.95)),
            (elliptic_arc(0.4, 0.75, 0.45, 0.2, -pi/2, 0) + line_pts((0.85, 0.75), (0.85, 0.95))[1:]),
        ],
        'u': [
            line_pts((0.1, 0.05), (0.5, 0.5)),
            line_pts((0.9, 0.05), (0.5, 0.5)),
            line_pts((0.5, 0.5), (0.5, 0.95)),
        ],
        'f': [
            line_pts((0.5, 0.05), (0.5, 0.95)),
            circle_arc(0.5, 0.5, 0.35, -pi/2, 3*pi/2),
        ],
        'h': [
            line_pts((0.1, 0.05), (0.9, 0.95)),
            line_pts((0.9, 0.05), (0.1, 0.95)),
        ],
        'c': [
            (line_pts((0.1, 0.05), (0.1, 0.70), 6) +
             curve_through((0.1, 0.70), (0.5, 0.90), (0.85, 0.70))[1:] +
             line_pts((0.85, 0.70), (0.85, 0.05), 6)[1:]),
            line_pts((0.75, 0.85), (0.75, 0.98)),
        ],
        'ch': [
            line_pts((0.75, 0.05), (0.75, 0.95)),
            curve_through((0.15, 0.05), (0.15, 0.35), (0.75, 0.5)),
        ],
        'dzh': [
            (line_pts((0.1, 0.05), (0.1, 0.70), 6) +
             curve_through((0.1, 0.70), (0.5, 0.90), (0.85, 0.70))[1:] +
             line_pts((0.85, 0.70), (0.85, 0.05), 6)[1:]),
            line_pts((0.47, 0.85), (0.47, 0.98)),
        ],
        'sh': [
            line_pts((0.1, 0.05), (0.1, 0.95)),
            line_pts((0.5, 0.05), (0.5, 0.95)),
            line_pts((0.9, 0.05), (0.9, 0.95)),
            line_pts((0.1, 0.95), (0.9, 0.95)),
        ],
    }


def cyrillic_lowercase_letter_strokes():
    # Body zone: y 0.20-0.85. Ascenders extend to y 0.05; descenders reach
    # y ~0.95. Mirrors CyrillicStrokeDefinitions.swift's lowercase section.
    return {
        'a': [
            # Visually identical to Latin a — Cyrillic standardized on the
            # Latin-style round form for а rather than a scaled-down А.
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.85)),
        ],
        'b': [
            line_pts((0.2, 0.05), (0.2, 0.85)),
            line_pts((0.2, 0.05), (0.55, 0.05)),
            elliptic_arc(0.2, 0.6, 0.55, 0.25, -pi/2, pi/2),
        ],
        'v': [
            line_pts((0.15, 0.2), (0.15, 0.85)),
            (elliptic_arc(0.15, 0.36, 0.5, 0.16, -pi/2, pi/2) +
             elliptic_arc(0.15, 0.69, 0.55, 0.16, -pi/2, pi/2)[1:]),
        ],
        'g': [
            line_pts((0.15, 0.2), (0.75, 0.2)),
            line_pts((0.15, 0.2), (0.15, 0.85)),
        ],
        'd': [
            line_pts((0.15, 0.2), (0.85, 0.2)),
            (line_pts((0.15, 0.2), (0.15, 0.75)) + line_pts((0.15, 0.75), (0.05, 0.85))[1:]),
            (line_pts((0.85, 0.2), (0.85, 0.75)) + line_pts((0.85, 0.75), (0.95, 0.85))[1:]),
            line_pts((0.15, 0.75), (0.85, 0.75)),
        ],
        'dj': [
            line_pts((0.1, 0.18), (0.4, 0.18)),
            line_pts((0.25, 0.05), (0.25, 0.85), 8),
            (elliptic_arc(0.25, 0.68, 0.4, 0.17, -pi/2, 0) +
             line_pts((0.65, 0.68), (0.65, 0.72), 2)[1:] +
             curve_through((0.65, 0.72), (0.55, 0.88), (0.4, 0.8))[1:]),
        ],
        'e': [
            line_pts((0.12, 0.5), (0.88, 0.5)),
            circle_arc(0.5, 0.5, 0.38, 0, -5*pi/3),
        ],
        'zh': [
            line_pts((0.5, 0.2), (0.5, 0.85)),
            line_pts((0.1, 0.2), (0.5, 0.52)),
            line_pts((0.5, 0.52), (0.1, 0.85)),
            line_pts((0.9, 0.2), (0.5, 0.52)),
            line_pts((0.5, 0.52), (0.9, 0.85)),
        ],
        'z': [
            (elliptic_arc(0.4, 0.36, 0.38, 0.16, -pi/2, pi/2) +
             elliptic_arc(0.4, 0.69, 0.42, 0.16, -pi/2, pi/2)[1:]),
        ],
        'i': [
            line_pts((0.15, 0.2), (0.15, 0.85)),
            line_pts((0.15, 0.85), (0.85, 0.2)),
            line_pts((0.85, 0.2), (0.85, 0.85)),
        ],
        'j': [
            (line_pts((0.5, 0.2), (0.5, 0.8), 5) + curve_through((0.5, 0.8), (0.33, 0.95), (0.17, 0.88))[1:]),
        ],
        'k': [
            line_pts((0.15, 0.2), (0.15, 0.85)),
            line_pts((0.85, 0.2), (0.15, 0.53)),
            line_pts((0.15, 0.53), (0.85, 0.85)),
        ],
        'l': [
            line_pts((0.15, 0.85), (0.5, 0.2)),
            line_pts((0.5, 0.2), (0.85, 0.85)),
        ],
        'lj': [
            line_pts((0.2, 0.2), (0.55, 0.2)),
            (line_pts((0.2, 0.2), (0.2, 0.7), 5) + curve_through((0.2, 0.7), (0.12, 0.87), (0.05, 0.8))[1:]),
            line_pts((0.55, 0.2), (0.55, 0.85)),
            elliptic_arc(0.55, 0.68, 0.35, 0.18, -pi/2, pi/2),
        ],
        'm': [
            line_pts((0.1, 0.2), (0.1, 0.85)),
            line_pts((0.1, 0.2), (0.5, 0.68)),
            line_pts((0.5, 0.68), (0.9, 0.2)),
            line_pts((0.9, 0.2), (0.9, 0.85)),
        ],
        'n': [
            line_pts((0.15, 0.2), (0.15, 0.85)),
            line_pts((0.85, 0.2), (0.85, 0.85)),
            line_pts((0.15, 0.52), (0.85, 0.52)),
        ],
        'nj': [
            line_pts((0.15, 0.2), (0.15, 0.85)),
            line_pts((0.5, 0.2), (0.5, 0.85)),
            line_pts((0.15, 0.5), (0.5, 0.5)),
            elliptic_arc(0.5, 0.68, 0.4, 0.18, -pi/2, pi/2),
        ],
        'o': [
            circle_arc(0.5, 0.5, 0.38, -pi/2, 3*pi/2),
        ],
        'p': [
            line_pts((0.12, 0.2), (0.88, 0.2)),
            line_pts((0.12, 0.2), (0.12, 0.85)),
            line_pts((0.88, 0.2), (0.88, 0.85)),
        ],
        'r': [
            line_pts((0.2, 0.2), (0.2, 0.95)),
            elliptic_arc(0.2, 0.38, 0.55, 0.2, -pi/2, pi/2),
        ],
        's': [
            circle_arc(0.5, 0.5, 0.38, -pi/3, -5*pi/3),
        ],
        't': [
            line_pts((0.15, 0.2), (0.85, 0.2)),
            line_pts((0.5, 0.2), (0.5, 0.85)),
        ],
        'tj': [
            line_pts((0.1, 0.18), (0.4, 0.18)),
            line_pts((0.25, 0.05), (0.25, 0.85), 8),
            (elliptic_arc(0.25, 0.68, 0.4, 0.17, -pi/2, 0) + line_pts((0.65, 0.68), (0.65, 0.85))[1:]),
        ],
        'u': [
            line_pts((0.15, 0.2), (0.5, 0.55)),
            (line_pts((0.85, 0.2), (0.5, 0.55), 4) +
             line_pts((0.5, 0.55), (0.5, 0.8), 3)[1:] +
             curve_through((0.5, 0.8), (0.35, 0.95), (0.2, 0.88))[1:]),
        ],
        'f': [
            line_pts((0.5, 0.05), (0.5, 0.95)),
            circle_arc(0.5, 0.5, 0.32, -pi/2, 3*pi/2),
        ],
        'h': [
            line_pts((0.15, 0.2), (0.85, 0.85)),
            line_pts((0.85, 0.2), (0.15, 0.85)),
        ],
        'c': [
            (line_pts((0.15, 0.2), (0.15, 0.70), 5) +
             curve_through((0.15, 0.70), (0.5, 0.85), (0.85, 0.70))[1:] +
             line_pts((0.85, 0.70), (0.85, 0.2), 5)[1:]),
            line_pts((0.7, 0.8), (0.7, 0.95)),
        ],
        'ch': [
            line_pts((0.75, 0.2), (0.75, 0.85)),
            curve_through((0.2, 0.2), (0.2, 0.45), (0.75, 0.55)),
        ],
        'dzh': [
            (line_pts((0.15, 0.2), (0.15, 0.70), 5) +
             curve_through((0.15, 0.70), (0.5, 0.85), (0.85, 0.70))[1:] +
             line_pts((0.85, 0.70), (0.85, 0.2), 5)[1:]),
            line_pts((0.47, 0.8), (0.47, 0.95)),
        ],
        'sh': [
            line_pts((0.12, 0.2), (0.12, 0.85)),
            line_pts((0.5, 0.2), (0.5, 0.85)),
            line_pts((0.88, 0.2), (0.88, 0.85)),
            line_pts((0.12, 0.85), (0.88, 0.85)),
        ],
    }


# Serbian alphabetical order, paired with the ASCII asset-name fragments
# used by CyrillicAlphabet.swift — must stay in sync with that file.
CYRILLIC_ASCII_NAMES = [
    'a', 'b', 'v', 'g', 'd', 'dj', 'e', 'zh', 'z', 'i', 'j', 'k',
    'l', 'lj', 'm', 'n', 'nj', 'o', 'p', 'r', 's', 't', 'tj', 'u',
    'f', 'h', 'c', 'ch', 'dzh', 'sh',
]


def german_upper_strokes():
    """Ports GermanStrokeDefinitions.swift's 3 new uppercase glyphs."""
    def dot(x, y):
        return line_pts((x, y), (x + 0.07, y), 3)

    return {
        'ae': [
            line_pts((0.5, 0.25), (0.95, 0.95)),
            line_pts((0.5, 0.25), (0.05, 0.95)),
            line_pts((0.2, 0.68), (0.8, 0.68)),
            dot(0.35, 0.08),
            dot(0.58, 0.08),
        ],
        'oe': [
            circle_arc(0.5, 0.6, 0.35, -pi/2, 3*pi/2),
            dot(0.35, 0.08),
            dot(0.58, 0.08),
        ],
        'ue': [
            (line_pts((0.1, 0.25), (0.1, 0.745), 6) +
             curve_through((0.1, 0.745), (0.5, 0.95), (0.9, 0.745))[1:] +
             line_pts((0.9, 0.745), (0.9, 0.25), 6)[1:]),
            dot(0.35, 0.08),
            dot(0.58, 0.08),
        ],
    }


def german_lower_strokes():
    """Ports GermanStrokeDefinitions.swift's 4 new lowercase glyphs."""
    def dot(x, y):
        return line_pts((x, y), (x + 0.07, y), 3)

    return {
        'ae': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.85)),
            dot(0.30, 0.06),
            dot(0.55, 0.06),
        ],
        'oe': [
            circle_arc(0.5, 0.50, 0.38, -pi/2, 3*pi/2),
            dot(0.34, 0.06),
            dot(0.59, 0.06),
        ],
        'ue': [
            (line_pts((0.12, 0.15), (0.12, 0.65), 4) +
             curve_through((0.12, 0.65), (0.5, 0.92), (0.88, 0.65))[1:] +
             line_pts((0.88, 0.65), (0.88, 0.15), 4)[1:]),
            dot(0.30, 0.06),
            dot(0.58, 0.06),
        ],
        'ss': [
            line_pts((0.35, 0.05), (0.35, 0.85)),
            elliptic_arc(0.35, 0.27, 0.32, 0.20, -pi/2, pi/2*0.6),
            elliptic_arc(0.35, 0.65, 0.42, 0.20, -pi/2*0.6, pi/2*0.75),
        ],
    }


# Asset-name fragments for German's 4 non-ASCII characters, shared between
# upper (3: ae/oe/ue) and lower (4: ae/oe/ue/ss) — must stay in sync with
# GermanAlphabet.swift's `specialAssetNames`.
GERMAN_UPPER_ASCII_NAMES = ['ae', 'oe', 'ue']
GERMAN_LOWER_ASCII_NAMES = ['ae', 'oe', 'ue', 'ss']


def _acute(x, y):
    return line_pts((x, y + 0.10), (x + 0.12, y), 3)


def spanish_upper_strokes():
    """Ports SpanishStrokeDefinitions.swift's 6 new uppercase glyphs.
    Ü isn't included here — it reuses German's 'ue' image, same as the
    Swift side reuses GermanStrokeDefinitions for that glyph."""
    return {
        'aacute': [
            line_pts((0.5, 0.25), (0.95, 0.95)),
            line_pts((0.5, 0.25), (0.05, 0.95)),
            line_pts((0.2, 0.68), (0.8, 0.68)),
            _acute(0.42, 0.06),
        ],
        'eacute': [
            line_pts((0.15, 0.25), (0.15, 0.95)),
            line_pts((0.15, 0.25), (0.85, 0.25)),
            line_pts((0.15, 0.60), (0.7, 0.60)),
            line_pts((0.15, 0.95), (0.85, 0.95)),
            _acute(0.42, 0.06),
        ],
        'iacute': [
            line_pts((0.5, 0.25), (0.5, 0.95)),
            _acute(0.42, 0.06),
        ],
        'oacute': [
            circle_arc(0.5, 0.6, 0.35, -pi/2, 3*pi/2),
            _acute(0.42, 0.06),
        ],
        'uacute': [
            (line_pts((0.1, 0.25), (0.1, 0.745), 6) +
             curve_through((0.1, 0.745), (0.5, 0.95), (0.9, 0.745))[1:] +
             line_pts((0.9, 0.745), (0.9, 0.25), 6)[1:]),
            _acute(0.42, 0.06),
        ],
        'enye': [
            line_pts((0.15, 0.25), (0.15, 0.95)),
            line_pts((0.15, 0.25), (0.85, 0.95)),
            line_pts((0.85, 0.25), (0.85, 0.95)),
            (curve_through((0.15, 0.13), (0.32, 0.03), (0.5, 0.09)) +
             curve_through((0.5, 0.09), (0.68, 0.15), (0.85, 0.05))[1:]),
        ],
    }


def spanish_lower_strokes():
    """Ports SpanishStrokeDefinitions.swift's 6 new lowercase glyphs."""
    return {
        'aacute': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.85)),
            _acute(0.36, -0.02),
        ],
        'eacute': [
            line_pts((0.12, 0.50), (0.88, 0.50)),
            circle_arc(0.5, 0.50, 0.38, 0, -5*pi/3),
            _acute(0.44, -0.08),
        ],
        'iacute': [
            line_pts((0.5, 0.22), (0.5, 0.85)),
            _acute(0.44, -0.02),
        ],
        'oacute': [
            circle_arc(0.5, 0.50, 0.38, -pi/2, 3*pi/2),
            _acute(0.44, -0.08),
        ],
        'uacute': [
            (line_pts((0.12, 0.15), (0.12, 0.65), 4) +
             curve_through((0.12, 0.65), (0.5, 0.92), (0.88, 0.65))[1:] +
             line_pts((0.88, 0.65), (0.88, 0.15), 4)[1:]),
            _acute(0.44, -0.02),
        ],
        'enye': [
            line_pts((0.18, 0.22), (0.18, 0.85)),
            (curve_through((0.18, 0.47), (0.50, 0.22), (0.80, 0.47)) +
             line_pts((0.80, 0.47), (0.80, 0.85), 5)[1:]),
            (curve_through((0.10, 0.09), (0.27, -0.01), (0.45, 0.05)) +
             curve_through((0.45, 0.05), (0.62, 0.11), (0.80, 0.01))[1:]),
        ],
    }


# Asset-name fragments for Spanish's 6 own special characters — must stay
# in sync with SpanishAlphabet.swift's `specialAssetNames`. Ü/ü is handled
# separately (reuses the German images generated above).
SPANISH_ASCII_NAMES = ['enye', 'aacute', 'eacute', 'iacute', 'oacute', 'uacute']


def swedish_upper_strokes():
    """Ports SwedishStrokeDefinitions.swift's new uppercase glyph (Å)."""
    return {
        'aring': [
            line_pts((0.5, 0.25), (0.95, 0.95)),
            line_pts((0.5, 0.25), (0.05, 0.95)),
            line_pts((0.2, 0.68), (0.8, 0.68)),
            circle_arc(0.5, 0.05, 0.07, -pi/2, 3*pi/2),
        ],
    }


def swedish_lower_strokes():
    """Ports SwedishStrokeDefinitions.swift's new lowercase glyph (å)."""
    return {
        'aring': [
            circle_arc(0.42, 0.52, 0.30, -pi/2, 3*pi/2),
            line_pts((0.72, 0.22), (0.72, 0.85)),
            circle_arc(0.5, 0.02, 0.065, -pi/2, 3*pi/2),
        ],
    }


# Asset-name fragment for Swedish's own special character Å/å — must stay
# in sync with SwedishAlphabet.swift's `specialAssetNames`. Ä/Ö/ä/ö reuse
# the German images generated above.
SWEDISH_ASCII_NAMES = ['aring']


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


def _write_imageset(xcassets: str, name: str, png: bytes) -> None:
    imageset_dir = os.path.join(xcassets, f'{name}.imageset')
    os.makedirs(imageset_dir, exist_ok=True)
    with open(os.path.join(imageset_dir, f'{name}.png'), 'wb') as f:
        f.write(png)
    write_json(os.path.join(imageset_dir, 'Contents.json'), {
        'images': [{'filename': f'{name}.png', 'idiom': 'universal', 'scale': '1x'}],
        'info': {'author': 'xcode', 'version': 1},
        'properties': {'template-rendering-intent': 'original'},
    })
    print(f'  {name}.png')


def main():
    root = os.path.dirname(os.path.abspath(__file__))
    xcassets = os.path.join(root, 'LetterQuest', 'Assets.xcassets')
    os.makedirs(xcassets, exist_ok=True)

    write_json(os.path.join(xcassets, 'Contents.json'), {
        'info': {'author': 'xcode', 'version': 1}
    })

    uppercase_strokes = all_letter_strokes()
    lowercase_strokes = lowercase_letter_strokes()
    cyrillic_upper_strokes = cyrillic_uppercase_letter_strokes()
    cyrillic_lower_strokes = cyrillic_lowercase_letter_strokes()

    # Uppercase: template_A … template_Z
    for char in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
        pixels = render_letter(uppercase_strokes[char], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_{char}'
        _write_imageset(xcassets, name, png)

    # Lowercase: template_lc_a … template_lc_z
    # The "lc_" prefix avoids case-collision with uppercase on macOS HFS+/APFS.
    # Letter.lowercaseAlphabet uses templateImageName = "template_lc_<char>".
    for char in 'abcdefghijklmnopqrstuvwxyz':
        pixels = render_letter(lowercase_strokes[char], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_lc_{char}'
        _write_imageset(xcassets, name, png)

    # Serbian Cyrillic uppercase: template_cyr_a … template_cyr_sh
    # Filenames use ASCII transliterations (CYRILLIC_ASCII_NAMES), matching
    # CyrillicAlphabet.swift — raw Cyrillic in a filename is a footgun for
    # git/Xcode asset-catalog tooling.
    for name_fragment in CYRILLIC_ASCII_NAMES:
        pixels = render_letter(cyrillic_upper_strokes[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_cyr_{name_fragment}'
        _write_imageset(xcassets, name, png)

    # Serbian Cyrillic lowercase: template_cyr_lc_a … template_cyr_lc_sh
    for name_fragment in CYRILLIC_ASCII_NAMES:
        pixels = render_letter(cyrillic_lower_strokes[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_cyr_lc_{name_fragment}'
        _write_imageset(xcassets, name, png)

    # German's 4 non-ASCII characters (the other 26 reuse the uppercase/
    # lowercase Latin templates above as-is): template_de_ae/oe/ue and
    # template_de_lc_ae/oe/ue/ss.
    german_upper = german_upper_strokes()
    german_lower = german_lower_strokes()

    for name_fragment in GERMAN_UPPER_ASCII_NAMES:
        pixels = render_letter(german_upper[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_de_{name_fragment}'
        _write_imageset(xcassets, name, png)

    for name_fragment in GERMAN_LOWER_ASCII_NAMES:
        pixels = render_letter(german_lower[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_de_lc_{name_fragment}'
        _write_imageset(xcassets, name, png)

    # Spanish's 6 own special characters (the other 26 reuse the Latin
    # templates above, and Ü/ü reuses German's template_de_ue images):
    # template_es_enye/aacute/eacute/iacute/oacute/uacute and
    # template_es_lc_enye/aacute/eacute/iacute/oacute/uacute.
    spanish_upper = spanish_upper_strokes()
    spanish_lower = spanish_lower_strokes()

    for name_fragment in SPANISH_ASCII_NAMES:
        pixels = render_letter(spanish_upper[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_es_{name_fragment}'
        _write_imageset(xcassets, name, png)

    for name_fragment in SPANISH_ASCII_NAMES:
        pixels = render_letter(spanish_lower[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_es_lc_{name_fragment}'
        _write_imageset(xcassets, name, png)

    # Swedish's own special character (the other 26 reuse the Latin
    # templates above, and Ä/Ö/ä/ö reuse German's template_de_* images):
    # template_sv_aring and template_sv_lc_aring.
    swedish_upper = swedish_upper_strokes()
    swedish_lower = swedish_lower_strokes()

    for name_fragment in SWEDISH_ASCII_NAMES:
        pixels = render_letter(swedish_upper[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_sv_{name_fragment}'
        _write_imageset(xcassets, name, png)

    for name_fragment in SWEDISH_ASCII_NAMES:
        pixels = render_letter(swedish_lower[name_fragment], SIZE, MARGIN, STROKE_RADIUS)
        png = encode_png(pixels, SIZE)
        name = f'template_sv_lc_{name_fragment}'
        _write_imageset(xcassets, name, png)

    print(f'\nAsset catalog written to:\n  {xcassets}')


if __name__ == '__main__':
    main()
