import CoreGraphics
import Testing

@testable import ContourTracer

/// Tests for ContourTracer parameters and callbacks.
struct ParameterBehaviorTests {

  @Test func stopsAfterFirstContourWhenCallbackReturnsFalse() {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    let rect1 = makeRectangleGrid(
      size: gridSize, origin: (x: 1, y: 1), rectSize: (width: 2, height: 2))
    let rect2 = makeRectangleGrid(
      size: gridSize, origin: (x: 6, y: 6), rectSize: (width: 2, height: 2))
    for y in 0..<gridSize { for x in 0..<gridSize { grid[y][x] = rect1[y][x] || rect2[y][x] } }

    var discoveredContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        discoveredContours.append(contourPath)
        return false
      }
    )
    #expect(discoveredContours.count == 1)

    var allContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        allContours.append(contourPath)
        return true
      }
    )
    #expect(allContours.count == 2)
  }

  @Test func respectsRowScanningFilterToFindOnlyEligibleContours() {
    let gridSize = 10
    var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    let rect1 = makeRectangleGrid(
      size: gridSize, origin: (x: 1, y: 2), rectSize: (width: 2, height: 1))
    let rect2 = makeRectangleGrid(
      size: gridSize, origin: (x: 6, y: 7), rectSize: (width: 2, height: 1))
    for y in 0..<gridSize { for x in 0..<gridSize { grid[y][x] = rect1[y][x] || rect2[y][x] } }

    var evenRowContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { row in row % 2 == 0 },
      onContourTraced: { contourPath in
        evenRowContours.append(contourPath)
        return true
      }
    )
    #expect(evenRowContours.count == 1)

    var oddRowContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { row in row % 2 == 1 },
      onContourTraced: { contourPath in
        oddRowContours.append(contourPath)
        return true
      }
    )
    #expect(oddRowContours.count == 1)

    var allContours: [CGPath] = []
    ContourTracer.trace(
      size: (width: gridSize, height: gridSize),
      canTrace: { tile in grid[tile.row][tile.col] },
      shouldScan: { _ in true },
      onContourTraced: { contourPath in
        allContours.append(contourPath)
        return true
      }
    )
    #expect(allContours.count == 2)
  }
}
