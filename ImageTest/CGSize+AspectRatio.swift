import Foundation

extension CGSize {
    func sizeWithHeight(height: CGFloat) -> CGSize! {
        let oldHeight: CGFloat = self.height;
        let scaleFactor: CGFloat = height / oldHeight;
        
        let newWidth: CGFloat = self.width * scaleFactor;
        let newHeight: CGFloat = oldHeight * scaleFactor;
        
        return CGSizeMake(newWidth, newHeight);
    }
    
    func sizeWithWidth(width: CGFloat) -> CGSize! {
        let oldWidth: CGFloat = self.width;
        let scaleFactor: CGFloat = width / oldWidth;
        
        let newHeight: CGFloat = self.height * scaleFactor;
        let newWidth: CGFloat = oldWidth * scaleFactor;
        
        return CGSizeMake(newWidth, newHeight);
    }
}