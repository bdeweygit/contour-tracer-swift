public typealias PixelPoint = (x: Int, y: Int)
public typealias ImageSize = (width: Int, height: Int)
public typealias Trace = (contour: [PixelPoint], centroid: (x: Double, y: Double), area: Double)

struct Tracer {
    enum Direction: Int {
        case front = 0, frontRight, right, rightRear, rear, leftRear, left, frontLeft
    }
    private enum AbsoluteDirection: Int, CaseIterable {
        case north = 0, northEast, east, southEast, south, southWest, west, northWest
    }

    private let pixelAtAbsoluteDirection = [
        AbsoluteDirection.east: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y) },
        AbsoluteDirection.west: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y) },
        AbsoluteDirection.north: { (p: PixelPoint) -> PixelPoint in (p.x, p.y - 1) },
        AbsoluteDirection.south: { (p: PixelPoint) -> PixelPoint in (p.x, p.y + 1) },
        AbsoluteDirection.northEast: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y - 1) },
        AbsoluteDirection.southWest: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y + 1) },
        AbsoluteDirection.northWest: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y - 1) },
        AbsoluteDirection.southEast: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y + 1) },
    ]

    var trace: Trace? {
        get {
            guard let first = contour.first, let last = contour.last, self.pixel.x == first.x && self.pixel.y == first.y && self.absoluteDirection == .west else {
                return nil
            }

            let area = abs(Double(self.sumArea + ((last.x * first.y) - (last.y * first.x))) / 2)
            let centroidX = Double(self.sumX) / Double(self.contour.count)
            let centroidY = Double(self.sumY) / Double(self.contour.count)
            return (self.contour, (centroidX, centroidY), area)
        }
    }

    private var pixel: PixelPoint, absoluteDirection = AbsoluteDirection.west
    private var contour = [PixelPoint](), sumX = 0, sumY = 0, sumArea = 0

    init(_ pixel: PixelPoint, _ history: inout Set<String>) {
        self.pixel = pixel
        self.updateTrace(&history)
    }

    func pixelToThe(_ direction: Direction) -> PixelPoint {
        let absoluteDir = absoluteDirectionAfterRotatingToThe(direction)
        return pixelAtAbsoluteDirection[absoluteDir]!(pixel)
    }

    mutating func moveToThe(_ direction: Direction?, andRotateToThe rotation: Direction?, _ history: inout Set<String>) {
        if let dir = direction {
            self.pixel = self.pixelToThe(dir)
            self.updateTrace(&history)
        }
        if let rot = rotation {
            self.absoluteDirection = self.absoluteDirectionAfterRotatingToThe(rot)
        }
    }

    private func absoluteDirectionAfterRotatingToThe(_ direction: Direction) -> AbsoluteDirection {
        let index = (self.absoluteDirection.rawValue + direction.rawValue) % AbsoluteDirection.allCases.count
        return AbsoluteDirection.allCases[index]
    }

    private mutating func updateTrace(_ history: inout Set<String>) {
        guard !history.contains(self.pixel) else { return }
        defer { history.insert(pixel) }

        self.sumX += self.pixel.x
        self.sumY += self.pixel.y
        if let last = self.contour.last { self.sumArea += (last.x * self.pixel.y) - (last.y * self.pixel.x) }
        self.contour.append(pixel)
    }
}

public func traceInImageOfSize(_ size: ImageSize, isActiveAt: (PixelPoint) -> Bool, shouldScanRow: (Int) -> Bool, shouldContinueAfterTracing: (Trace) -> Bool) {
    guard size.width > 0 && size.height > 0 else { return }

    let perimeter = (size.width + (size.height - 2)) * 2
    var history = Set<String>(minimumCapacity: perimeter)

    for row in 0..<size.height {
        // verify row should be scanned
        if shouldScanRow(row) {
            for col in 0..<size.width {
                // verify pixel is active, was not in a previous trace, and is a valid starting pixel
                let pixel: PixelPoint = (x: col, y: row)
                if isActiveAt(pixel) && !history.contains(pixel) && !isActiveAt((pixel.x - 1, pixel.y)) && (!isActiveAt((pixel.x - 1, pixel.y + 1)) || isActiveAt((pixel.x, pixel.y + 1))) {
                    // start tracing
                    var tracer = Tracer(pixel, &history)
                    while true {
                        if isActiveAt(tracer.pixelToThe(.leftRear)) {
                            if isActiveAt(tracer.pixelToThe(.left)) {
                                tracer.moveToThe(.left, andRotateToThe: .left, &history)
                                tracer.moveToThe(.left, andRotateToThe: .left, &history)
                            } else {
                                tracer.moveToThe(.leftRear, andRotateToThe: .rear, &history)
                            }
                        } else if isActiveAt(tracer.pixelToThe(.left)) {
                            tracer.moveToThe(.left, andRotateToThe: .left, &history)
                        }
                        if isActiveAt(tracer.pixelToThe(.frontLeft)) {
                            if isActiveAt(tracer.pixelToThe(.front)) {
                                tracer.moveToThe(.front, andRotateToThe: .left, &history)
                                tracer.moveToThe(.front, andRotateToThe: .right, &history)
                            } else {
                               tracer.moveToThe(.frontLeft, andRotateToThe: nil, &history)
                            }
                        } else if isActiveAt(tracer.pixelToThe(.front)) {
                            tracer.moveToThe(.front, andRotateToThe: .right, &history)
                        } else {
                            tracer.moveToThe(nil, andRotateToThe: .rear, &history)
                        }

                        if let trace = tracer.trace { // finished tracing
                            guard shouldContinueAfterTracing(trace) else { return }
                            break
                        }
                    }
                }
            }
        }
    }
}

extension Set where Element == String {
    func contains(_ pixel: PixelPoint) -> Bool {
        return self.contains("\(pixel.x).\(pixel.y)")
    }

    mutating func insert(_ pixel: PixelPoint) {
        self.insert("\(pixel.x).\(pixel.y)")
    }
}
