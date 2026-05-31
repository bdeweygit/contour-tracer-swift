# ContourTracer

A Swift implementation of the pixel-following contour tracing algorithm, based on ["Fast Contour-Tracing Algorithm Based on a Pixel-Following Method for Image Sensors" (Sensors 2016, 16, 353)](https://www.mdpi.com/1424-8220/16/3/353).

## Coordinate System and Path Coordinates

Rows and columns are **zero-indexed**: tile `(row: 0, col: 0)` is at the extreme top-left of the tessellation.

Each tile occupies the unit square `[col, col+1] × [row, row+1]`. The returned CGPath traces the **pixel-edge boundary** — the geometric outline of the enclosed tiles — with vertices at tile corners rather than tile centers.

For example, a 4×3 rectangle of tiles at origin `(3, 3)` produces a path from `(3, 3)` to `(7, 6)` with area 12, matching the pixel count. The path can be directly compared with other CGPaths (e.g., `CGPath(rect:)`) without coordinate-convention mismatch.

The pixel-edge path is built by a vertex-following boundary follower that runs after the pixel-following algorithm identifies the contour. At each pixel-edge corner, the four surrounding tiles determine the next edge direction, producing a clockwise polygon (screen coordinates) with the traceable region on the right side of the boundary.

## Algorithm Overview

ContourTracer scans a tessellation grid and runs the pixel-following algorithm on each unvisited boundary tile to trace closed contours. The implementation is data-format agnostic — it only requires data organized as an N×M grid, hence "tiles" rather than "pixels."

### Key Features

- **Pixel-Following Method**: Uses directional movement and rotation to follow shape boundaries.
- **Complete Contour Detection**: Traces closed contours and detects completion automatically.
- **Callback-Based Architecture**: Provides flexible control over scanning and early termination.
