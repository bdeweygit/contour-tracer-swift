public typealias PixelPoint = (x: Int, y: Int)
public typealias ImageSize = (width: Int, height: Int)

struct Tracer {
    var pixel: PixelPoint
    var absoluteDirection: AbsoluteDirection

    enum AbsoluteDirection: Int, CaseIterable {
        case north = 0, northEast, east, southEast, south, southWest, west, northWest
    }

    enum Direction: Int {
        case front = 0, frontRight, right, rightRear, rear, leftRear, left, frontLeft
    }

    private let pixelAtAbsoluteDirection = [
        AbsoluteDirection.north: { (p: PixelPoint) -> PixelPoint in (p.x, p.y - 1)},
        AbsoluteDirection.northEast: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y - 1)},
        AbsoluteDirection.east: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y)},
        AbsoluteDirection.southEast: { (p: PixelPoint) -> PixelPoint in (p.x - 1, p.y + 1)},
        AbsoluteDirection.south: { (p: PixelPoint) -> PixelPoint in (p.x, p.y + 1)},
        AbsoluteDirection.southWest: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y + 1)},
        AbsoluteDirection.west: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y)},
        AbsoluteDirection.northWest: { (p: PixelPoint) -> PixelPoint in (p.x + 1, p.y - 1)},
    ]

    private func absoluteDirectionAfterRotatingToThe(_ direction: Direction) -> AbsoluteDirection {
        let index = (self.absoluteDirection.rawValue + direction.rawValue) % AbsoluteDirection.allCases.count
        return AbsoluteDirection.allCases[index]
    }

    func pixelToThe(_ direction: Direction) -> PixelPoint {
        let absDir = self.absoluteDirectionAfterRotatingToThe(direction)
        return self.pixelAtAbsoluteDirection[absDir]!(self.pixel)
    }

    mutating func moveToThe(_ direction: Direction?, andRotateToThe rotation: Direction?) {
        self.pixel = direction == nil ? self.pixel : self.pixelToThe(direction!)
        self.absoluteDirection = rotation == nil ? self.absoluteDirection : self.absoluteDirectionAfterRotatingToThe(rotation!)
    }

}

func contourStartsAt(_ pixel: PixelPoint, _ isActiveAt: (PixelPoint) -> Bool) -> Bool {
    let isActive = isActiveAt(pixel)
    if isActive {
        let (x, y) = pixel
        let isRearInactive = !isActiveAt((x - 1, y))
        if isRearInactive {
            let isLeftRearInactive = !isActiveAt((x - 1, y + 1))
            if isLeftRearInactive {
                return true
            } // left rear pixel is active
            return isActiveAt((x, y + 1)) // is left pixel white?
        } // rear pixel is active
        return false
    } // pixel is inactive
    return false
}

public func traceContoursInImageOfSize(_ size: ImageSize, isActiveAt: (PixelPoint) -> Bool, shouldScanRow: (Int) -> Bool, shouldContinueAfterTracingContour: ([PixelPoint]) -> Bool) {
    let minimumCapacity = (size.width + (size.height - 2)) * 2 // outline of image
    var traced = Set<String>(minimumCapacity: minimumCapacity)
    let startAbsoluteDirection = Tracer.AbsoluteDirection.west // <- why?

    for row in 0..<size.height {
        if !shouldScanRow(row) { continue }
        for col in 0..<size.width {
            let startPixel: PixelPoint = (x: col, y: row)

            // skip if pixel was already traced
            if traced.contains(startPixel) { continue }

            if contourStartsAt(startPixel, isActiveAt) { // start contour tracing
                var contour = [PixelPoint]()
                var tracer = Tracer(pixel: startPixel, absoluteDirection: startAbsoluteDirection)
                traced.insert(tracer.pixel)

                repeat {
                    if isActiveAt(tracer.pixelToThe(.leftRear)) {
                        if isActiveAt(tracer.pixelToThe(.left)) {
                            tracer.moveToThe(.left, andRotateToThe: .left)
                            traced.insert(tracer.pixel)

                            contour.append(tracer.pixel)

                            tracer.moveToThe(.left, andRotateToThe: .left)
                            traced.insert(tracer.pixel)
                        } else {
                            contour.append(tracer.pixel)

                            tracer.moveToThe(.leftRear, andRotateToThe: .rear)
                            traced.insert(tracer.pixel)

                            contour.append(tracer.pixel)
                        }
                    } else {
                        if isActiveAt(tracer.pixelToThe(.left)) {
                            tracer.moveToThe(.left, andRotateToThe: .left)
                            traced.insert(tracer.pixel)

                            contour.append(tracer.pixel)
                        } else {
                            contour.append(tracer.pixel)
                        }
                    }
                    if isActiveAt(tracer.pixelToThe(.frontLeft)) {
                        if isActiveAt(tracer.pixelToThe(.front)) {
                            tracer.moveToThe(.front, andRotateToThe: .left)
                            traced.insert(tracer.pixel)

                            contour.append(tracer.pixel)

                            tracer.moveToThe(.front, andRotateToThe: .right)
                            traced.insert(tracer.pixel)
                        } else {
                            contour.append(tracer.pixel)

                            tracer.moveToThe(.frontLeft, andRotateToThe: nil)
                            traced.insert(tracer.pixel)

                            contour.append(tracer.pixel)
                        }
                    } else if isActiveAt(tracer.pixelToThe(.front)) {
                        tracer.moveToThe(.front, andRotateToThe: .right)
                        traced.insert(tracer.pixel)
                    } else {
                        tracer.moveToThe(nil, andRotateToThe: .rear)

                        contour.append(tracer.pixel)
                    }
                } while (tracer.pixel.x != startPixel.x || tracer.pixel.y != startPixel.y || tracer.absoluteDirection != startAbsoluteDirection)

                if !shouldContinueAfterTracingContour(contour) { return }
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
