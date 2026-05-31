import CoreGraphics
import Testing

// MARK: - CGPath Helpers

/// Extracts integer coordinate points from a CGPath for testing validation.
/// - Parameter path: CGPath to extract points from.
/// - Returns: Array of integer coordinate tuples representing path points.
func extractPointsFromCGPath(_ path: CGPath) -> [(x: Int, y: Int)] {
  var points: [(x: Int, y: Int)] = []
  path.applyWithBlock({ elementPtr in
    let element = elementPtr.pointee
    switch element.type {
    case .moveToPoint, .addLineToPoint:
      let p = element.points[0]
      points.append((x: Int(round(p.x)), y: Int(round(p.y))))
    case .closeSubpath:
      break
    default:
      break
    }
  })
  return points
}

/// Validates that a traced contour correctly follows the expected boundary points.
/// - Parameters:
///   - tracedPoints: Points traced by the contour algorithm.
///   - expectedBoundary: Expected boundary points for validation.
func validateContourTrace(
  tracedPoints: [(x: Int, y: Int)], expectedBoundary: [(x: Int, y: Int)]
) {
  #expect(!tracedPoints.isEmpty, "Contour trace should not be empty")
  #expect(!expectedBoundary.isEmpty, "Expected boundary should not be empty")

  let boundarySet = Set(expectedBoundary.map({ "\($0.x),\($0.y)" }))
  for point in tracedPoints {
    let key = "\(point.x),\(point.y)"
    #expect(
      boundarySet.contains(key), "Traced point (\(point.x),\(point.y)) is not on expected boundary")
  }

  let tracedSet = Set(tracedPoints.map({ "\($0.x),\($0.y)" }))
  #expect(
    tracedSet.count == boundarySet.count,
    "Contour covers \(tracedSet.count) of \(boundarySet.count) expected boundary corners")

  validateContourConnectivity(tracedPoints)
}

/// Validates that consecutive contour points are 4-connected (horizontal or vertical, no diagonals).
/// - Parameter points: Array of contour points to validate connectivity.
func validateContourConnectivity(_ points: [(x: Int, y: Int)]) {
  guard points.count > 1 else { return }
  for i in 0..<(points.count - 1) {
    let a = points[i]
    let b = points[i + 1]
    #expect(
      abs(a.x - b.x) + abs(a.y - b.y) == 1,
      "Points (\(a.x),\(a.y)) and (\(b.x),\(b.y)) are not adjacent")
  }
}

// MARK: - Grid Factories

/// Makes a boolean grid with a rectangular region marked as true.
/// - Parameters:
///   - size: Grid dimensions (makes size x size grid).
///   - origin: Top-left corner coordinates of the rectangle.
///   - rectSize: Rectangle dimensions (width and height).
/// - Returns: 2D boolean array with rectangle region marked as true.
func makeRectangleGrid(
  size: Int, origin: (x: Int, y: Int), rectSize: (width: Int, height: Int)
) -> [[Bool]] {
  var grid = Array(repeating: Array(repeating: false, count: size), count: size)
  for y in origin.y..<(origin.y + rectSize.height) {
    for x in origin.x..<(origin.x + rectSize.width) {
      if x >= 0 && x < size && y >= 0 && y < size { grid[y][x] = true }
    }
  }
  return grid
}

/// Makes a boolean grid with a circular region marked as true.
/// - Parameters:
///   - size: Grid dimensions (makes size x size grid).
///   - center: Circle center coordinates as floating point values.
///   - radius: Circle radius in grid units.
/// - Returns: 2D boolean array with circular region marked as true.
func makeCircleGrid(size: Int, center: (x: Double, y: Double), radius: Double) -> [[Bool]] {
  var grid = Array(repeating: Array(repeating: false, count: size), count: size)
  for y in 0..<size {
    for x in 0..<size {
      let dx = Double(x) - center.x
      let dy = Double(y) - center.y
      let distance = sqrt(dx * dx + dy * dy)
      if distance <= radius { grid[y][x] = true }
    }
  }
  return grid
}

// MARK: - Boundary Calculations

/// Calculates the expected pixel-edge boundary corners for a shape defined by a boolean grid.
///
/// For each filled boundary pixel, determines which 4-connected neighbors are unfilled
/// and adds the pixel-edge corners of those exterior edges to the result.
///
/// - Parameters:
///   - grid: 2D boolean array where true values represent the shape interior.
///   - gridSize: The dimensions of the square grid.
/// - Returns: Array of pixel-edge corner coordinates along the boundary (deduplicated).
func calculateExpectedGridBoundary(grid: [[Bool]], gridSize: Int) -> [(x: Int, y: Int)] {
  var cornerSet = Set<String>()
  var boundary: [(x: Int, y: Int)] = []
  func addCorner(_ x: Int, _ y: Int) {
    let key = "\(x),\(y)"
    guard !cornerSet.contains(key) else { return }
    cornerSet.insert(key)
    boundary.append((x: x, y: y))
  }
  for y in 0..<gridSize {
    for x in 0..<gridSize {
      guard grid[y][x] else { continue }
      // Top exterior: neighbor above is unfilled or out of bounds
      if y == 0 || !grid[y - 1][x] {
        addCorner(x, y)
        addCorner(x + 1, y)
      }
      // Right exterior
      if x == gridSize - 1 || !grid[y][x + 1] {
        addCorner(x + 1, y)
        addCorner(x + 1, y + 1)
      }
      // Bottom exterior
      if y == gridSize - 1 || !grid[y + 1][x] {
        addCorner(x + 1, y + 1)
        addCorner(x, y + 1)
      }
      // Left exterior
      if x == 0 || !grid[y][x - 1] {
        addCorner(x, y + 1)
        addCorner(x, y)
      }
    }
  }
  return boundary
}
