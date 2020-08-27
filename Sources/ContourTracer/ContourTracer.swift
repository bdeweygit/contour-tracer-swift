public typealias PixelPoint = (x: Int, y: Int)
public typealias ImageSize = (width: Int, height: Int)

public struct ContourTracer {
    private typealias Tracer = (pixel: PixelPoint, absoluteDirection: AbsoluteDirection)

    private enum AbsoluteDirection: Int, CaseIterable {
        case north = 0, northEast, east, southEast, south, southWest, west, northWest
    }

    private enum Direction: Int {
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

    private func absoluteDirectionAfterRotatingToThe(_ direction: Direction, of tracer: Tracer) -> AbsoluteDirection {
        let index = (tracer.absoluteDirection.rawValue + direction.rawValue) % AbsoluteDirection.allCases.count
        return AbsoluteDirection.allCases[index]
    }

    private func pixelToThe(_ direction: Direction, of tracer: Tracer) -> PixelPoint {
        let absDir = self.absoluteDirectionAfterRotatingToThe(direction, of: tracer)
        return self.pixelAtAbsoluteDirection[absDir]!(tracer.pixel)
    }

    private func move(_ tracer: inout Tracer, toThe dir: Direction?, andRotateToThe rot: Direction?) {
        let pixel = dir == nil ? tracer.pixel : self.pixelToThe(dir!, of: tracer)
        let absoluteDirection = rot == nil ? tracer.absoluteDirection : self.absoluteDirectionAfterRotatingToThe(rot!, of: tracer)
        tracer = (pixel, absoluteDirection)
    }

    private func add(_ pixel: PixelPoint, to traced: inout [String : Bool]) {
        traced["\(pixel.x).\(pixel.y)"] = true
    }

    private func pixelAt(_ pixel: PixelPoint, was traced: [String : Bool]) -> Bool {
        return traced["\(pixel.x).\(pixel.y)"] ?? false
    }

    private func contourStartsAt(_ pixel: PixelPoint, _ isActiveAt: (PixelPoint) -> Bool) -> Bool {
        let isActive = isActiveAt(pixel)
        if isActive {
            let (x, y) = pixel
            let isRearInactive = !isActiveAt((x - 1, y))
            if isRearInactive {
                let isLeftRearInactive = !isActiveAt((x - 1, y + 1))
                if isLeftRearInactive {
                    return true
                } // left rear is active
                return isActiveAt((x, y + 1)) // is left white?
            } // it's rear is active
            return false
        } // it's inactive
        return false
    }

    public func trace(onImageOfSize size: ImageSize, _ isActiveAt: (PixelPoint) -> Bool) {
        var traced = [String : Bool]()
        let startAbsoluteDirection = AbsoluteDirection.west // <- why?

        for y in 0..<size.height {
            for x in 0..<size.width {
                // skip if pixel was already traced
                if self.pixelAt((x, y), was: traced) { continue }

                if self.contourStartsAt((x, y), isActiveAt) { // start contour tracing
                    var contour = [PixelPoint]()
                    var tracer: Tracer = (pixel: (x, y), absoluteDirection: startAbsoluteDirection)
                    self.add(tracer.pixel, to: &traced)

                    repeat {
                        if isActiveAt(self.pixelToThe(.leftRear, of: tracer)) {
                            if isActiveAt(self.pixelToThe(.left, of: tracer)) {
                                self.move(&tracer, toThe: .left, andRotateToThe: .left)
                                self.add(tracer.pixel, to: &traced)

                                contour.append(tracer.pixel)

                                self.move(&tracer, toThe: .left, andRotateToThe: .left)
                                self.add(tracer.pixel, to: &traced)
                            } else {
                                contour.append(tracer.pixel)

                                self.move(&tracer, toThe: .leftRear, andRotateToThe: .rear)
                                self.add(tracer.pixel, to: &traced)

                                contour.append(tracer.pixel)
                            }
                        } else {
                            if isActiveAt(self.pixelToThe(.left, of: tracer)) {
                                self.move(&tracer, toThe: .left, andRotateToThe: .left)
                                self.add(tracer.pixel, to: &traced)

                                contour.append(tracer.pixel)
                            } else {
                                contour.append(tracer.pixel)
                            }
                        }
                        if isActiveAt(self.pixelToThe(.frontLeft, of: tracer)) {
                            if isActiveAt(self.pixelToThe(.front, of: tracer)) {
                                self.move(&tracer, toThe: .front, andRotateToThe: .left)
                                self.add(tracer.pixel, to: &traced)

                                contour.append(tracer.pixel)

                                self.move(&tracer, toThe: .front, andRotateToThe: .right)
                                self.add(tracer.pixel, to: &traced)
                            } else {
                                contour.append(tracer.pixel)

                                self.move(&tracer, toThe: .frontLeft, andRotateToThe: nil)
                                self.add(tracer.pixel, to: &traced)

                                contour.append(tracer.pixel)
                            }
                        } else if isActiveAt(self.pixelToThe(.front, of: tracer)) {
                            self.move(&tracer, toThe: .front, andRotateToThe: .right)
                            self.add(tracer.pixel, to: &traced)
                        } else {
                            self.move(&tracer, toThe: nil, andRotateToThe: .rear)

                            contour.append(tracer.pixel)
                        }
                    } while (tracer.pixel.x != x || tracer.pixel.y != y || tracer.absoluteDirection != startAbsoluteDirection)

                    // do something with contour
                    //
                    //
                }
            }
        }
    }
}


