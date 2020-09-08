public typealias Row = Int
public typealias Tile = (x: Int, y: Int)
public typealias TessellationSize = (width: Int, height: Int)
public typealias Contour = (tiles: [Tile], centroid: (x: Double, y: Double), area: Double)

public struct ContourTracer {
    public static func trace(size: TessellationSize, canTrace: (Tile) -> Bool, shouldScan: (Row) -> Bool, shouldContinueAfterTracing: (Contour) -> Bool) {
        guard size.width > 0 && size.height > 0 else { return }

        // record traced tiles to avoid tracing the same contour more than once
        var history = TileSet(idOf: { ($0.y * (size.width - 1)) + $0.x })

        // scan the tessellation tiles
        for row in 0..<size.height {
            // verify row should be scanned
            guard shouldScan(row) else { continue }
            for col in 0..<size.width {
                // verify tile was not in a previously traced contour and can initialize a tracer
                let tile: Tile = (x: col, y: row)
                guard !history.contains(tile), var tracer = Tracer(tile, canTrace, &history) else { continue }

                // start tracing
                while true {
                    // first stage
                    if canTrace(tracer.tileAt(.leftRear)) {
                        if canTrace(tracer.tileAt(.left)) {
                            tracer.move(.left, andRotate: .left, &history)
                            tracer.move(.left, andRotate: .left, &history)
                        } else {
                            tracer.move(.leftRear, andRotate: .rear, &history)
                        }
                    } else if canTrace(tracer.tileAt(.left)) {
                        tracer.move(.left, andRotate: .left, &history)
                    }

                    // second stage
                    if canTrace(tracer.tileAt(.frontLeft)) {
                        if canTrace(tracer.tileAt(.front)) {
                            tracer.move(.front, andRotate: .left, &history)
                            tracer.move(.front, andRotate: .right, &history)
                        } else {
                           tracer.move(.frontLeft, andRotate: nil, &history)
                        }
                    } else if canTrace(tracer.tileAt(.front)) {
                        tracer.move(.front, andRotate: .right, &history)
                    } else {
                        tracer.move(nil, andRotate: .rear, &history)
                    }

                    if let contour = tracer.contour { // done tracing
                        // verify scan should continue
                        guard shouldContinueAfterTracing(contour) else { return }
                        break
                    }
                }
            }
        }
    }
}
