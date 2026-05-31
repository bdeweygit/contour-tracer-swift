public import CoreGraphics

/// A row index in the tessellation grid.
public typealias Row = Int

/// A coordinate pair representing a tile position in the tessellation grid.
/// The row increases downward, column increases rightward (zero-indexed).
public typealias Tile = (row: Int, col: Int)

/// The dimensions of a tessellation grid as (width, height) in tile units.
public typealias TessellationSize = (width: Int, height: Int)

/// Callback result that determines whether to continue scanning for additional contours.
/// - `true`: Continue scanning for more contours.
/// - `false`: Stop scanning and return.
public typealias ContinueScan = Bool

/// A contour tracer that implements the pixel-following algorithm for shape boundary detection.
///
/// This tracer systematically scans a tessellation grid to identify and trace the boundaries
/// of shapes using the two-stage pixel-following algorithm from "Fast Contour-Tracing Algorithm
/// Based on a Pixel-Following Method for Image Sensors" (Sensors 2016). It provides
/// flexible control over scanning and early termination through callback functions.
public enum ContourTracer {

  // MARK: - Tracing

  /// Traces contours in a tessellation, calling back with each discovered shape.
  /// - Parameters:
  ///   - size: The dimensions of the tessellation grid.
  ///   - canTrace: Function to determine if a tile in the tessellation can be traced.
  ///   - shouldScan: Function to determine if a row in the tessellation should be scanned.
  ///   - onContourTraced: Function called with each discovered contour's CGPath; return false to stop scanning.
  public static func trace(
    size: TessellationSize,
    canTrace: (Tile) -> Bool,
    shouldScan: (Row) -> Bool,
    onContourTraced: (CGPath) -> ContinueScan
  ) {
    guard size.width > 0 && size.height > 0 else { return }

    var history = TileSet(tessellationWidth: size.width)

    for row in 0..<size.height {
      guard shouldScan(row) else { continue }
      for col in 0..<size.width {
        let tile = (row: row, col: col)
        guard !history.contains(tile),
          var tracer = Tracer.make(tile: tile, size: size, canTrace: canTrace, &history)
        else { continue }

        // Two-stage pixel-following algorithm.
        // Stage 1 queries left-rear and left directions, Stage 2 queries front-left and front.
        while true {
          // Stage 1: Query left-rear and left pixels
          if let leftRearTile = tracer.tileAt(.leftRear), canTrace(leftRearTile) {
            if let leftTile = tracer.tileAt(.left), canTrace(leftTile) {
              tracer.move(.left, andRotate: .left, &history)
              tracer.move(.left, andRotate: .left, &history)
            } else {
              tracer.move(.leftRear, andRotate: .rear, &history)
            }
          } else if let leftTile = tracer.tileAt(.left), canTrace(leftTile) {
            tracer.move(.left, andRotate: .left, &history)
          }

          // Stage 2: Query front-left and front pixels
          if let frontLeftTile = tracer.tileAt(.frontLeft), canTrace(frontLeftTile) {
            if let frontTile = tracer.tileAt(.front), canTrace(frontTile) {
              tracer.move(.front, andRotate: .left, &history)
              tracer.move(.front, andRotate: .right, &history)
            } else {
              tracer.move(.frontLeft, andRotate: nil, &history)
            }
          } else if let frontTile = tracer.tileAt(.front), canTrace(frontTile) {
            tracer.move(.front, andRotate: .right, &history)
          } else {
            // No traceable pixels: rotate 180° to continue
            tracer.move(nil, andRotate: .rear, &history)
          }

          if let contour = tracer.contour(canTrace: canTrace) {
            guard onContourTraced(contour) else { return }
            break
          }
        }
      }
    }
  }
}
