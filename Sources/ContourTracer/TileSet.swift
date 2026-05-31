/// A collection that efficiently stores and checks membership of tiles.
///
/// This struct uses a 2D-to-1D coordinate mapping to store tiles as unique
/// integer identifiers in a Set, providing O(1) insertion and lookup operations.
/// The mapping formula is: `id = row * tessellationWidth + col`.
struct TileSet {

  // MARK: - Properties

  private var ids = Set<Int>()

  private let tessellationWidth: Int

  // MARK: - Initialization

  /// Initializes a TileSet for a tessellation of the given width.
  /// - Parameter tessellationWidth: The width of the tessellation grid.
  init(tessellationWidth: Int) {
    self.tessellationWidth = tessellationWidth
  }

  // MARK: - Membership

  /// Adds a tile to the set.
  /// - Parameter tile: The tile to add.
  mutating func insert(_ tile: Tile) {
    ids.insert(idOf(tile))
  }

  /// Returns whether the set contains the given tile.
  /// - Parameter tile: The tile to check.
  /// - Returns: Whether the tile is in the set.
  func contains(_ tile: Tile) -> Bool {
    return ids.contains(idOf(tile))
  }

  // MARK: - Identifier mapping

  /// Converts a tile to a unique identifier.
  /// - Parameter tile: The tile to convert.
  /// - Returns: A unique integer identifier for the tile.
  private func idOf(_ tile: Tile) -> Int {
    return tile.row * tessellationWidth + tile.col
  }
}
