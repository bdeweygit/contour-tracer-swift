import CoreGraphics

extension CGPath {
  var area: CGFloat {
    var subpaths: [[CGPoint]] = []
    var current: [CGPoint] = []

    applyWithBlock({ element in
      switch element.pointee.type {
      case .moveToPoint:
        if current.count >= 3 { subpaths.append(current) }
        current = [element.pointee.points[0]]
      case .addLineToPoint:
        current.append(element.pointee.points[0])
      case .addQuadCurveToPoint:
        assertionFailure("area only supports polygonal paths; quad curve not handled")
        current.append(element.pointee.points[1])
      case .addCurveToPoint:
        assertionFailure("area only supports polygonal paths; cubic curve not handled")
        current.append(element.pointee.points[2])
      case .closeSubpath:
        break
      @unknown default:
        break
      }
    })
    if current.count >= 3 { subpaths.append(current) }

    return subpaths.reduce(CGFloat.zero, { total, points in
      var sum = CGFloat.zero
      for i in 0..<points.count {
        let j = (i + 1) % points.count
        sum += points[i].x * points[j].y - points[j].x * points[i].y
      }
      return total + abs(sum) / 2.0
    })
  }
}
