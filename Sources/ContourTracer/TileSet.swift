struct TileSet {
    var ids = Set<Int>()
    let tessellationWidth: Int

    init(tessellationWidth: Int) {
        self.tessellationWidth = tessellationWidth
    }

    private func idOf(_ tile: Tile) -> Int {
        return (tile.y * self.tessellationWidth) + tile.x
    }

    mutating func insert(_ tile: Tile) {
        self.ids.insert(self.idOf(tile))
    }

    func contains(_ tile: Tile) -> Bool {
        return self.ids.contains(self.idOf(tile))
    }
}
