struct TileSet {
    var ids = Set<Int>()
    let idOf: (Tile) -> Int

    init(idOf: @escaping (Tile) -> Int) {
        self.idOf = idOf
    }

    mutating func insert(_ tile: Tile) {
        self.ids.insert(self.idOf(tile))
    }

    func contains(_ tile: Tile) -> Bool {
        return self.ids.contains(self.idOf(tile))
    }
}
