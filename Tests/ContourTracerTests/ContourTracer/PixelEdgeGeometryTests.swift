import CoreGraphics
import Testing

@testable import ContourTracer

/// Verifies that ContourTracer produces pixel-edge polygons with exact geometric properties.
///
/// The CGPath must represent the exact geometric boundary of the enclosed pixels:
/// - Area (shoelace) equals the pixel count.
/// - CGPath.contains returns true for pixel centers inside the shape, false outside.
struct PixelEdgeGeometryTests {

  // MARK: - Helpers

  /// Traces a boolean grid and returns the first contour found.
  private func traceFirst(_ grid: [[Bool]], width: Int, height: Int) -> CGPath? {
    var result: CGPath?
    ContourTracer.trace(
      size: (width: width, height: height),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contour in
        result = contour
        return false
      }
    )
    return result
  }

  /// Counts filled pixels in a grid.
  private func pixelCount(_ grid: [[Bool]]) -> Int {
    grid.reduce(0, { $0 + $1.filter({ $0 }).count })
  }

  // MARK: - Area equals pixel count

  @Test(arguments: [
    (origin: (x: 3, y: 3), size: (width: 4, height: 3), gridSize: 10),
    (origin: (x: 0, y: 0), size: (width: 1, height: 1), gridSize: 5),
    (origin: (x: 0, y: 0), size: (width: 10, height: 10), gridSize: 10),
    (origin: (x: 1, y: 1), size: (width: 6, height: 2), gridSize: 10),
    (origin: (x: 2, y: 0), size: (width: 3, height: 8), gridSize: 10),
  ])
  func rectangleAreaEqualsPixelCount(
    origin: (x: Int, y: Int), size: (width: Int, height: Int), gridSize: Int
  ) {
    let grid = makeRectangleGrid(size: gridSize, origin: origin, rectSize: size)
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    let expectedArea = CGFloat(size.width * size.height)
    #expect(contour.area == expectedArea)
  }

  @Test func circleAreaEqualsPixelCount() {
    let gridSize = 20
    let grid = makeCircleGrid(size: gridSize, center: (x: 10.0, y: 10.0), radius: 5.0)
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    let expected = CGFloat(pixelCount(grid))
    #expect(contour.area == expected)
  }

  @Test func lShapeAreaEqualsPixelCount() {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    // Horizontal bar: 4×2 at (2,3)
    for x in 2...5 {
      grid[3][x] = true
      grid[4][x] = true
    }
    // Vertical bar: 2×2 at (2,5)
    for y in 5...6 {
      grid[y][2] = true
      grid[y][3] = true
    }

    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    let expected = CGFloat(pixelCount(grid))
    #expect(contour.area == expected)
  }

  @Test func singlePixelAreaIsOne() {
    var grid = Array(repeating: Array(repeating: false, count: 5), count: 5)
    grid[2][2] = true
    let contour = traceFirst(grid, width: 5, height: 5)!
    #expect(contour.area == 1.0)
  }

  @Test func thinHorizontalLineAreaEqualsLength() {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for x in 2..<8 { grid[4][x] = true }
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    #expect(contour.area == 6.0)
  }

  @Test func thinVerticalLineAreaEqualsLength() {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for y in 1..<7 { grid[y][5] = true }
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    #expect(contour.area == 6.0)
  }

  @Test func fullyFilledGridAreaEqualsTotal() {
    let gridSize = 4
    let grid = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    #expect(contour.area == 16.0)
  }

  // MARK: - Point containment

  @Test func rectangleContainsAllEnclosedPixels() {
    let gridSize = 10
    let origin = (x: 3, y: 3)
    let size = (width: 4, height: 3)
    let grid = makeRectangleGrid(size: gridSize, origin: origin, rectSize: size)
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!

    for row in 0..<gridSize {
      for col in 0..<gridSize {
        let point = CGPoint(x: CGFloat(col) + 0.5, y: CGFloat(row) + 0.5)
        let expected = grid[row][col]
        #expect(contour.contains(point) == expected)
      }
    }
  }

  @Test func circleContainsAllEnclosedPixels() {
    let gridSize = 16
    let grid = makeCircleGrid(size: gridSize, center: (x: 8.0, y: 8.0), radius: 4.0)
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!

    for row in 0..<gridSize {
      for col in 0..<gridSize {
        let point = CGPoint(x: CGFloat(col) + 0.5, y: CGFloat(row) + 0.5)
        let expected = grid[row][col]
        #expect(contour.contains(point) == expected)
      }
    }
  }

  // MARK: - Edge-touching shapes

  @Test func shapeTouchingGridBoundaryHasCorrectArea() {
    let gridSize = 8
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for y in 0..<3 { for x in 0..<4 { grid[y][x] = true } }
    let contour = traceFirst(grid, width: gridSize, height: gridSize)!
    #expect(contour.area == 12.0)
  }

  @Test func fourCornersHaveCorrectIndividualAreas() {
    let gridSize = 6
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    let corners = [(0, 0), (0, gridSize - 2), (gridSize - 2, 0), (gridSize - 2, gridSize - 2)]
    for (startY, startX) in corners {
      for y in startY..<(startY + 2) { for x in startX..<(startX + 2) { grid[y][x] = true } }
    }

    var totalArea = CGFloat.zero
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contour in
        #expect(contour.area == 4.0, "Each 2×2 corner should have area 4")
        totalArea += contour.area
        return true
      }
    )
    #expect(totalArea == 16.0, "Four 2×2 corners should total area 16")
  }
}
