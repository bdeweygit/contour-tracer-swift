struct Tracer {
    enum Direction: Int {
        case front = 0, frontRight, right, rightRear, rear, leftRear, left, frontLeft
    }

    private enum Compass: Int, CaseIterable {
        case north = 0, northEast, east, southEast, south, southWest, west, northWest

        func rotated(_ direction: Direction) -> Compass {
            let index = (self.rawValue + direction.rawValue) % Compass.allCases.count
            return Compass.allCases[index]
        }
    }

    static func create(tile: Tile, canTrace: (Tile) -> Bool, _ history: inout TileSet) -> Tracer? {
        return canTrace(tile) && !canTrace((tile.x - 1, tile.y)) && (!canTrace((tile.x - 1, tile.y + 1)) || canTrace((tile.x, tile.y + 1))) ? Tracer(tile: tile, &history) : nil
    }

    private let tileAtCompass: [Compass : (Tile) -> Tile] = [
        .east: { (t: Tile) -> Tile in (t.x + 1, t.y) },
        .west: { (t: Tile) -> Tile in (t.x - 1, t.y) },
        .north: { (t: Tile) -> Tile in (t.x, t.y + 1) },
        .south: { (t: Tile) -> Tile in (t.x, t.y - 1) },
        .northEast: { (t: Tile) -> Tile in (t.x + 1, t.y + 1) },
        .southWest: { (t: Tile) -> Tile in (t.x - 1, t.y - 1) },
        .northWest: { (t: Tile) -> Tile in (t.x - 1, t.y + 1) },
        .southEast: { (t: Tile) -> Tile in (t.x + 1, t.y - 1) },
    ]

    var contour: Contour? {
        // verify tracer is on its initial tile and compass
        guard let first = self.tiles.first, let last = self.tiles.last, self.tile.x == first.x && self.tile.y == first.y && self.compass == .east else {
            return nil
        }

        // calculate area and centroid coordinates
        let area = abs(Double(self.sumArea + ((last.x * first.y) - (last.y * first.x))) / 2)
        let x = Double(self.sumX) / Double(self.tiles.count)
        let y = Double(self.sumY) / Double(self.tiles.count)

        return (self.tiles, (x, y), area)
    }

    private var tile: Tile, compass = Compass.east
    private var tiles = [Tile](), sumX = 0, sumY = 0, sumArea = 0

    private init(tile: Tile, _ history: inout TileSet) {
        self.tile = tile
        self.updateContour(&history)
    }

    func tileAt(_ direction: Direction) -> Tile {
        let map = self.tileAtCompass[self.compass.rotated(direction)]!
        return map(self.tile)
    }

    mutating func move(_ direction: Direction?, andRotate rotation: Direction?, _ history: inout TileSet) {
        if let dir = direction {
            self.tile = self.tileAt(dir)
            self.updateContour(&history)
        }
        if let rot = rotation {
            self.compass = self.compass.rotated(rot)
        }
    }

    private mutating func updateContour(_ history: inout TileSet) {
        guard !history.contains(self.tile) else { return }
        defer { history.insert(self.tile) }

        self.sumX += self.tile.x
        self.sumY += self.tile.y
        if let last = self.tiles.last { self.sumArea += (last.x * self.tile.y) - (last.y * self.tile.x) }
        self.tiles.append(self.tile)
    }
}
