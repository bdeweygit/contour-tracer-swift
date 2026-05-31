import CoreGraphics
import Testing

@testable import ContourTracer

/// Basic shape tracing tests for ContourTracer.
struct BasicShapesTests {

  @Test(arguments: [
    (
      shapeType: "rectangle", gridSize: 10, expectedContours: 1,
      description: "simple rectangle contour"
    ),
    (shapeType: "circle", gridSize: 12, expectedContours: 1, description: "simple circle contour"),
    (
      shapeType: "singlePixel", gridSize: 5, expectedContours: 1,
      description: "single pixel correctly"
    ),
    (shapeType: "empty", gridSize: 5, expectedContours: 0, description: "empty grid correctly"),
  ])
  func tracesBasicShapes(
    shapeType: String, gridSize: Int, expectedContours: Int, description: String
  ) {
    let grid: [[Bool]]
    let expectedBoundary: [(x: Int, y: Int)]

    switch shapeType {
    case "rectangle":
      grid = makeRectangleGrid(
        size: gridSize, origin: (x: 3, y: 3), rectSize: (width: 4, height: 3))
      expectedBoundary = calculateExpectedGridBoundary(grid: grid, gridSize: gridSize)
    case "circle":
      let center = (x: 6.0, y: 6.0)
      let radius = 3.0
      grid = makeCircleGrid(size: gridSize, center: center, radius: radius)
      expectedBoundary = calculateExpectedGridBoundary(grid: grid, gridSize: gridSize)
    case "singlePixel":
      var singlePixelGrid = Array(
        repeating: Array(repeating: false, count: gridSize), count: gridSize)
      singlePixelGrid[2][2] = true
      grid = singlePixelGrid
      expectedBoundary = calculateExpectedGridBoundary(grid: grid, gridSize: gridSize)
    case "empty":
      grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
      expectedBoundary = []
    default:
      fatalError("Invalid test data: unknown shape type \(shapeType)")
    }

    var discoveredContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        discoveredContours.append(contourPath)
        return true
      }
    )

    #expect(discoveredContours.count == expectedContours, "Should handle \(description)")

    if expectedContours > 0 {
      let tracedPoints = extractPointsFromCGPath(discoveredContours[0])
      validateContourTrace(tracedPoints: tracedPoints, expectedBoundary: expectedBoundary)
    }
  }

  @Test func tracesRectangleCircleAndPixelAsSeparateContours() {
    let gridSize = 15
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

    let rect = makeRectangleGrid(
      size: gridSize, origin: (x: 1, y: 1), rectSize: (width: 3, height: 2))
    let circle = makeCircleGrid(size: gridSize, center: (x: 8.0, y: 3.0), radius: 2.0)
    var singlePixel = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    singlePixel[12][12] = true

    for y in 0..<gridSize {
      for x in 0..<gridSize {
        grid[y][x] = rect[y][x] || circle[y][x] || singlePixel[y][x]
      }
    }

    var discoveredContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        discoveredContours.append(contourPath)
        return true
      }
    )

    #expect(
      discoveredContours.count == 3,
      "Should find rectangle, circle, and single pixel as separate contours")

    for contour in discoveredContours {
      #expect(!contour.isEmpty)
      let points = extractPointsFromCGPath(contour)
      #expect(!points.isEmpty)
    }
  }
}
