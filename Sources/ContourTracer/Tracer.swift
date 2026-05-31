import CoreGraphics

/// A stateful pixel-follower that traces the boundary of a single shape.
///
/// Maintains a tile position and compass orientation while visiting boundary tiles, detecting
/// completion when the tracer returns to its starting position facing east (Jacob's stopping
/// criterion). On completion, runs a vertex-following pass to build the pixel-edge CGPath —
/// vertices at tile corners rather than tile centers, so the polygon area equals the enclosed
/// tile count.
struct Tracer {

  // MARK: - Direction

  /// 8-directional movement system for boundary following.
  ///
  /// These directions are relative to the tracer's current orientation and are used
  /// for both movement and rotation operations during contour tracing.
  enum Direction: Int {
    /// Forward direction relative to current orientation.
    case front = 0
    /// The remaining 7 directions in clockwise order from front.
    case frontRight, right, rightRear, rear, leftRear, left, frontLeft
  }

  // MARK: - Properties

  /// Current tile position of the tracer in the tessellation.
  private var tile: Tile

  /// Current compass orientation of the tracer.
  ///
  /// Determines the absolute direction for relative movement and rotation operations.
  /// Always starts facing east and changes as the tracer follows contour boundaries.
  private var compass: Compass

  /// The tile where tracing began.
  private let startingTile: Tile

  /// Dimensions of the tessellation being traced.
  private let size: TessellationSize

  // MARK: - Initialization

  /// Initializes a tracer at the given tile.
  /// - Parameters:
  ///   - tile: The starting tile.
  ///   - size: The tessellation dimensions for bounds checking.
  ///   - history: Set of already traced tiles.
  private init(tile: Tile, size: TessellationSize, _ history: inout TileSet) {
    self.tile = tile
    self.startingTile = tile
    self.size = size
    self.compass = .east
    history.insert(tile)
  }

  // MARK: - Factory

  /// Returns whether a tracer can be made for the tile to start a valid contour.
  /// - Parameters:
  ///   - tile: The starting tile.
  ///   - size: The dimensions of the tessellation.
  ///   - canTrace: Function to determine if a tile can be traced.
  ///   - history: Set of already traced tiles.
  /// - Returns: A tracer if the tile can start a contour, nil otherwise.
  static func make(
    tile: Tile, size: TessellationSize, canTrace: (Tile) -> Bool, _ history: inout TileSet
  ) -> Tracer? {
    func canSafelyTrace(_ t: Tile) -> Bool {
      return tessellation(of: size, contains: t) && canTrace(t)
    }

    // Starting conditions: rear pixel must be non-traceable, avoiding left-rear inner-outer corners
    return canSafelyTrace(tile) && !canSafelyTrace((row: tile.row, col: tile.col - 1))
      && (!canSafelyTrace((row: tile.row + 1, col: tile.col - 1))
        || canSafelyTrace((row: tile.row + 1, col: tile.col)))
      ? Tracer(tile: tile, size: size, &history) : nil
  }

  // MARK: - Movement and tracing

  /// Returns the tile at the given relative direction if it's within the tessellation.
  /// - Parameter direction: The direction relative to the tracer's current orientation.
  /// - Returns: The tile at that direction, or nil if out of bounds.
  func tileAt(_ direction: Direction) -> Tile? {
    let adjacent = Self.neighbor(tile, facing: compass.rotated(direction))
    return Self.tessellation(of: size, contains: adjacent) ? adjacent : nil
  }

  /// Moves the tracer and/or rotates its orientation.
  /// - Parameters:
  ///   - direction: The direction to move, or nil to stay in place.
  ///   - rotation: The direction to rotate, or nil to maintain orientation.
  ///   - history: Set of already traced tiles.
  mutating func move(
    _ direction: Direction?, andRotate rotation: Direction?, _ history: inout TileSet
  ) {
    if let dir = direction, let nextTile = tileAt(dir) {
      tile = nextTile
      history.insert(tile)
    }
    if let rot = rotation {
      compass = compass.rotated(rot)
    }
  }

  /// Returns the completed contour path if tracing is finished, nil otherwise.
  ///
  /// The contour is complete when the tracer returns to its starting tile with the original
  /// east-facing orientation, following Jacob's stopping criterion. When complete, the
  /// pixel-edge boundary polygon is built by following exterior edges clockwise.
  ///
  /// - Parameter canTrace: Function to determine if a tile can be traced.
  /// - Returns: The pixel-edge boundary path, or nil if the contour is not yet complete.
  func contour(canTrace: (Tile) -> Bool) -> CGPath? {
    guard tile.row == startingTile.row && tile.col == startingTile.col && compass == .east
    else {
      return nil
    }
    return buildPixelEdgePath(canTrace: canTrace)
  }

  // MARK: - Tessellation geometry

  /// Absolute compass directions for mapping relative directions to tessellation coordinates.
  ///
  /// The compass system converts relative Direction values into absolute tessellation
  /// movements. North increases row (downward), east increases column (rightward).
  private enum Compass: Int, CaseIterable {
    case north = 0
    case northEast, east, southEast, south, southWest, west, northWest

    /// Returns the compass direction after rotating by the given direction.
    /// - Parameter direction: The direction to rotate by.
    /// - Returns: The resulting compass direction.
    func rotated(_ direction: Direction) -> Compass {
      let index = (rawValue + direction.rawValue) % Compass.allCases.count
      return Compass.allCases[index]
    }
  }

  /// Returns whether a tessellation of a given size contains a tile.
  /// - Parameters:
  ///   - tile: The tile to check.
  ///   - size: The dimensions of the tessellation.
  /// - Returns: Whether the tile is within the tessellation bounds.
  private static func tessellation(of size: TessellationSize, contains tile: Tile) -> Bool {
    return tile.row >= 0 && tile.row < size.height && tile.col >= 0 && tile.col < size.width
  }

  /// Returns the neighbor of a tile in a given compass direction.
  private static func neighbor(_ tile: Tile, facing compass: Compass) -> Tile {
    switch compass {
    case .east: return (row: tile.row, col: tile.col + 1)
    case .west: return (row: tile.row, col: tile.col - 1)
    case .north: return (row: tile.row + 1, col: tile.col)
    case .south: return (row: tile.row - 1, col: tile.col)
    case .northEast: return (row: tile.row + 1, col: tile.col + 1)
    case .southWest: return (row: tile.row - 1, col: tile.col - 1)
    case .northWest: return (row: tile.row + 1, col: tile.col - 1)
    case .southEast: return (row: tile.row - 1, col: tile.col + 1)
    }
  }

  // MARK: - Pixel-edge path

  /// Cardinal directions for the vertex-following boundary pass, clockwise in screen coordinates.
  private enum EdgeDirection {
    case right, down, left, up

    var dx: Int {
      switch self {
      case .right: 1
      case .down: 0
      case .left: -1
      case .up: 0
      }
    }

    var dy: Int {
      switch self {
      case .right: 0
      case .down: 1
      case .left: 0
      case .up: -1
      }
    }
  }

  /// Builds the pixel-edge boundary polygon by following exterior edges clockwise.
  ///
  /// Uses a vertex-following boundary follower. At each pixel-edge corner,
  /// the four surrounding pixels determine the next edge direction. The traceable region
  /// stays on the right side of the direction of travel (clockwise winding).
  ///
  /// - Parameter canTrace: Function to determine if a tile can be traced.
  /// - Returns: A closed CGPath tracing the pixel-edge boundary.
  private func buildPixelEdgePath(canTrace: (Tile) -> Bool) -> CGPath {
    let path = CGMutablePath()

    // Start at BL corner of starting tile, heading up (along the exterior left edge).
    var cx = startingTile.col
    var cy = startingTile.row + 1
    var dir = EdgeDirection.up

    path.move(to: CGPoint(x: cx, y: cy))

    repeat {
      cx += dir.dx
      cy += dir.dy
      path.addLine(to: CGPoint(x: cx, y: cy))
      dir = nextDirection(dir, cx: cx, cy: cy, canTrace: canTrace)
    } while cx != startingTile.col || cy != startingTile.row + 1

    path.closeSubpath()
    return path
  }

  /// Determines the next boundary direction at a pixel-edge corner.
  ///
  /// At each corner, the four surrounding pixels form a 2x2 cell. The boundary turns
  /// right, continues straight, or turns left based on which pixels are traceable.
  /// Priority: right turn > straight > left turn (clockwise winding).
  ///
  /// - Parameters:
  ///   - dir: The direction of arrival at this corner.
  ///   - cx: The x-coordinate of the corner.
  ///   - cy: The y-coordinate of the corner.
  ///   - canTrace: Function to determine if a tile can be traced.
  /// - Returns: The next direction to follow.
  private func nextDirection(
    _ dir: EdgeDirection, cx: Int, cy: Int, canTrace: (Tile) -> Bool
  ) -> EdgeDirection {
    func isTraceable(_ row: Int, _ col: Int) -> Bool {
      Self.tessellation(of: size, contains: (row: row, col: col))
        && canTrace((row: row, col: col))
    }

    // The four pixels sharing corner (cx, cy):
    // Upper-left: (cy-1, cx-1)   Upper-right: (cy-1, cx)
    // Lower-left: (cy, cx-1)     Lower-right: (cy, cx)
    switch dir {
    case .right:
      if !isTraceable(cy, cx) { return .down }
      if !isTraceable(cy - 1, cx) { return .right }
      return .up
    case .down:
      if !isTraceable(cy, cx - 1) { return .left }
      if !isTraceable(cy, cx) { return .down }
      return .right
    case .left:
      if !isTraceable(cy - 1, cx - 1) { return .up }
      if !isTraceable(cy, cx - 1) { return .left }
      return .down
    case .up:
      if !isTraceable(cy - 1, cx) { return .right }
      if !isTraceable(cy - 1, cx - 1) { return .up }
      return .left
    }
  }
}
