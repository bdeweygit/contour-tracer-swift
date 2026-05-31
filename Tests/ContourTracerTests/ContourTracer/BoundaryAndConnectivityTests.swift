import CoreGraphics
import Testing

@testable import ContourTracer

/// Boundary and connectivity tests for ContourTracer tessellations and shapes.
struct BoundaryAndConnectivityTests {

  @Test func tracesContourWhenShapeTouchesGridBoundary() {
    let gridSize = 8
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for y in 0..<3 { for x in 0..<4 { grid[y][x] = true } }

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
    #expect(discoveredContours.count == 1)
    #expect(!discoveredContours[0].isEmpty)
  }

  @Test func tracesContourWhenGridIsFullyFilled() {
    let gridSize = 4
    let grid = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)

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
    #expect(discoveredContours.count == 1)
    #expect(!discoveredContours[0].isEmpty)
    let tracedPoints = extractPointsFromCGPath(discoveredContours[0])
    #expect(!tracedPoints.isEmpty)
  }

  @Test(arguments: [
    (gridSize: 1, description: "1x1 tessellation with single filled pixel"),
    (gridSize: 2, description: "2x2 tessellation with corner pixel"),
  ])
  func tracesContoursInVerySmallGrids(gridSize: Int, description: String) {
    let grid: [[Bool]] = {
      switch gridSize {
      case 1: return [[true]]
      case 2:
        var g = Array(repeating: Array(repeating: false, count: 2), count: 2)
        g[0][0] = true
        return g
      default: fatalError("Invalid test data: unsupported grid size \(gridSize)")
      }
    }()

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
    #expect(discoveredContours.count == 1, "Should handle \(description)")
  }

  @Test func tracesFourSeparateContoursInFourCorners() {
    let gridSize = 6
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    let corners = [(0, 0), (0, gridSize - 2), (gridSize - 2, 0), (gridSize - 2, gridSize - 2)]
    for (startY, startX) in corners {
      for y in startY..<(startY + 2) { for x in startX..<(startX + 2) { grid[y][x] = true } }
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
    #expect(discoveredContours.count == 4)
    for contour in discoveredContours { #expect(!contour.isEmpty) }
  }

  @Test func mergesAdjacentTouchingShapesIntoSingleContour() {
    let gridSize = 8
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for y in 1...3 { for x in 1...3 { grid[y][x] = true } }
    for y in 1...3 { for x in 4...6 { grid[y][x] = true } }

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
    #expect(discoveredContours.count == 1)
    #expect(!discoveredContours[0].isEmpty)
  }

  @Test(arguments: [
    (orientation: "horizontal", description: "horizontal thin line"),
    (orientation: "vertical", description: "vertical thin line"),
  ])
  func tracesSingleContourForThinLinearShapes(orientation: String, description: String) {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    switch orientation {
    case "horizontal": for x in 2..<8 { grid[4][x] = true }
    case "vertical": for y in 1..<7 { grid[y][5] = true }
    default: fatalError("Invalid test data: unknown orientation \(orientation)")
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
    #expect(discoveredContours.count == 1, "Should handle \(description)")
    #expect(!discoveredContours[0].isEmpty, "\(description) should not be empty")
  }

  @Test func tracesNonConvexLShapedContour() {
    let gridSize = 8
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    for x in 2...5 {
      grid[3][x] = true
      grid[4][x] = true
    }
    for y in 5...6 {
      grid[y][2] = true
      grid[y][3] = true
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
    #expect(discoveredContours.count == 1)
    let tracedPoints = extractPointsFromCGPath(discoveredContours[0])
    let expectedBoundary = calculateExpectedGridBoundary(grid: grid, gridSize: gridSize)
    validateContourTrace(tracedPoints: tracedPoints, expectedBoundary: expectedBoundary)
  }

  @Test(arguments: [
    (width: 0, height: 0, description: "zero-size tessellation"),
    (width: 0, height: 5, description: "zero width tessellation"),
    (width: 5, height: 0, description: "zero height tessellation"),
  ])
  func yieldsNoContoursForZeroDimensionGrids(width: Int, height: Int, description: String) {
    var discoveredContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: width, height: height),
      canTrace: { _ in false },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        discoveredContours.append(contourPath)
        return true
      }
    )
    #expect(discoveredContours.isEmpty, "\(description) should yield no contours")
  }
}
