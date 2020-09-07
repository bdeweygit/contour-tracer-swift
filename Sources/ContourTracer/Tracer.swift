enum Direction: Int {
    case front = 0, frontRight, right, rightRear, rear, leftRear, left, frontLeft
}

fileprivate enum Compass: Int, CaseIterable {
    case north = 0, northEast, east, southEast, south, southWest, west, northWest

    func rotated(_ direction: Direction) -> Compass {
        let index = (self.rawValue + direction.rawValue) % Compass.allCases.count
        return Compass.allCases[index]
    }
}

fileprivate let tileAtCompass = [
    .east: { (t: Tile) -> Tile in (t.x - 1, t.y) },
    .west: { (t: Tile) -> Tile in (t.x + 1, t.y) },
    .north: { (t: Tile) -> Tile in (t.x, t.y - 1) },
    .south: { (t: Tile) -> Tile in (t.x, t.y + 1) },
    .northEast: { (t: Tile) -> Tile in (t.x - 1, t.y - 1) },
    .southWest: { (t: Tile) -> Tile in (t.x + 1, t.y + 1) },
    .northWest: { (t: Tile) -> Tile in (t.x + 1, t.y - 1) },
    Compass.southEast: { (t: Tile) -> Tile in (t.x - 1, t.y + 1) },
]

struct Tracer {
    var contour: Contour? {
        get {
            // verify tracer is on its initial tile and compass
            guard let first = self.tiles.first, let last = self.tiles.last, self.tile.x == first.x && self.tile.y == first.y && self.compass == .west else {
                return nil
            }

            // calculate area and centroid coordinates
            let area = abs(Double(self.sumArea + ((last.x * first.y) - (last.y * first.x))) / 2)
            let x = Double(self.sumX) / Double(self.tiles.count)
            let y = Double(self.sumY) / Double(self.tiles.count)

            return (self.tiles, (x, y), area)
        }
    }

    private var tile: Tile, compass = Compass.west
    private var tiles = [Tile](), sumX = 0, sumY = 0, sumArea = 0

    init?(_ tile: Tile, _ canTrace: (Tile) -> Bool, _ history: inout History) {
        self.tile = tile

        // verify a contour trace can begin at this tile
        guard canTrace(self.tile) && !canTrace(self.tileAt(.rear)) && (!canTrace(self.tileAt(.leftRear)) || canTrace(self.tileAt(.left))) else { return nil }

        self.updateContour(&history)
    }

    func tileAt(_ direction: Direction) -> Tile {
        let map = tileAtCompass[self.compass.rotated(direction)]!
        return map(self.tile)
    }

    mutating func move(_ direction: Direction?, andRotate rotation: Direction?, _ history: inout History) {
        if let dir = direction {
            self.tile = self.tileAt(dir)
            self.updateContour(&history)
        }
        if let rot = rotation {
            self.compass = self.compass.rotated(rot)
        }
    }

    private mutating func updateContour(_ history: inout History) {
        guard !history.contains(self.tile) else { return }
        defer { history.insert(self.tile) }

        self.sumX += self.tile.x
        self.sumY += self.tile.y
        if let last = self.tiles.last { self.sumArea += (last.x * self.tile.y) - (last.y * self.tile.x) }
        self.tiles.append(self.tile)
    }
}
