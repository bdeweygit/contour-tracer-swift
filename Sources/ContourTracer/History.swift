struct History {
    var x = Set<Int>()
    var y = Set<Int>()

    mutating func insert(_ tile: Tile) {
        self.x.insert(tile.x)
        self.y.insert(tile.y)
    }

    func contains(_ tile: Tile) -> Bool {
        return self.x.contains(tile.x) && self.y.contains(tile.y)
    }
}
