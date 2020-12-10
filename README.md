# Contour Tracer

>Seo, J.; Chae, S.; Shim, J.; Kim, D.; Cheong, C.; Han, T.-D. Fast Contour-Tracing Algorithm Based on a Pixel-Following Method for Image Sensors. Sensors 2016, 16, 353.

Implementation of _Fast Contour-Tracing_. This package only provides the tracing algorithm; it does not provide compressed contours or the contour restoration algorithm. The implementation is data format agnostic by leaving tile (typically a pixel) reads to the caller.
