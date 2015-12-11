import Foundation
import AsyncDisplayKit

extension ASNetworkImageNode {
    
    func setupPhotoViewer() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.removeExistingTapGesture()
            self.addTapGesture()
        }
 
    }
    
    func removeExistingTapGesture() {
        if let _: [AnyObject] = self.view.gestureRecognizers {
            for gesture in self.view.gestureRecognizers! {
                if !gesture.isKindOfClass(UIPanGestureRecognizer.self) {
                    self.view.removeGestureRecognizer(gesture)
                }
            }
        }
    }
    
    func addTapGesture() {
        self.userInteractionEnabled = true
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapImage:")
        self.view.addGestureRecognizer(tapGesture)
    }
    
    
    func didTapImage(gesture: UITapGestureRecognizer) {
        let photoViewer: PhotoViewController = PhotoViewController(imageView: self)
        photoViewer.loadView()
        if(self.image != nil) {
            photoViewer.presentFromRootViewController()
        }
        self.removeExistingTapGesture()
    }
}

