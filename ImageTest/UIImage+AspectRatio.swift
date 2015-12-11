import Foundation

public extension UIImage {
    
    func heightForWidth(width: CGFloat) -> CGFloat {
        return (self.size.height / self.size.width) * width;
    }
    
    func widthForHeight(height: CGFloat) -> CGFloat {
        return (self.size.width / self.size.height) * height
    }
    
    func sizeWithWidth(width: CGFloat) -> CGSize! {
        return self.size.sizeWithWidth(width)
    }
    
    func sizeWithHeight(height: CGFloat) -> CGSize! {
        return self.size.sizeWithHeight(height)
    }
    
}