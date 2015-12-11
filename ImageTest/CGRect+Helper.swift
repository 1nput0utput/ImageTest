import Foundation

extension CGRect {
    
    var center: CGPoint {
        return CGPointMake(midX, midY)
    }
    
    var bounds: CGRect {
        var rect = self
        rect.origin = CGPoint(x: 0.0, y: 0.0)
        return rect
    }
}