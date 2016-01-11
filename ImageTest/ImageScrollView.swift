import Foundation
import AsyncDisplayKit

class ImageScrollView: UIScrollView, UIScrollViewDelegate, ASNetworkImageNodeDelegate {
    
    var didEndZoomingBlock: ((Bool) -> Void)!
    var didZoomBlock: ((Bool) -> Void)!
    var handleSingleTapBlock: (() -> Void)!
    var doubleTapGesture: UITapGestureRecognizer!
    var singleTapGesture: UITapGestureRecognizer!
    
    private var scaleToRestoreAfterResize: CGFloat = 1.0
    private var pointToCenterAfterResize: CGPoint = CGPointZero
    
    var isZoomed: Bool {
        return self.zoomScale > self.minimumZoomScale
    }
    
    weak var photo: ASNetworkImageNode? {
        didSet {
            if let _ = self.photo?.image {
                self.contentSize = self.photo!.image!.size
            } else {
                self.photo?.delegate = self
            }
            
            self.addSubnode(self.photo!)
            self.setMaxMinZoomScalesForCurrentBounds()
            self.zoomScale = self.minimumZoomScale
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
        self.addGestures()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showImageView(imageView: ASNetworkImageNode) {
        self.zoomScale = 1.0
        self.photo = imageView
    }
    
    func centerFrame() -> CGRect {
        let boundsSize: CGSize = self.bounds.size
        var contentsFrame: CGRect = self.photo!.view.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        return contentsFrame
    }
    
    func handleSingleTap() {
        if(handleSingleTapBlock != nil) {
            self.handleSingleTapBlock()
        }
    }
    
    func handleDoubleTap(tapLocation: CGPoint) {
        if (isZoomed) {
            self.zoomToRect(self.centerFrame(), animated: true)
        } else  {
            let zoomScale: CGFloat = self.zoomScale > (self.maximumZoomScale/2) ? self.minimumZoomScale : self.maximumZoomScale
            self.zoomToRect(ImageScrollView.zoomRectForScrollView(self, scale: zoomScale, center: tapLocation), animated: true)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.photo?.view
    }
    
    class func zoomRectForScrollView(scrollView: UIScrollView!, scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect: CGRect = CGRectZero
        
        zoomRect.size.width  = scrollView.frame.width  / scale
        zoomRect.size.height = scrollView.frame.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    func maximumContentOffset() -> CGPoint {
        let contentSize: CGSize = self.contentSize
        let boundsSize: CGSize = self.bounds.size
        return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height)
    }
    
    func minimumContentOffset() -> CGPoint {
        return CGPointZero
    }
    
    func prepareToResize() {
        
        let boundsCenter: CGPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        
        self.pointToCenterAfterResize = self.convertPoint(boundsCenter, fromView: self.photo?.view)
        self.scaleToRestoreAfterResize = self.zoomScale
        
        if (self.scaleToRestoreAfterResize <= self.minimumZoomScale + CGFloat(FLT_EPSILON)) {
            self.scaleToRestoreAfterResize = 0
        }
    }
    
    func recoverFromResizing() {
        self.setMaxMinZoomScalesForCurrentBounds()
        
        self.zoomScale = min(self.maximumZoomScale, max(self.minimumZoomScale, self.scaleToRestoreAfterResize))
    
        let boundsCenter: CGPoint = self.convertPoint(self.pointToCenterAfterResize, fromView: self.photo?.view)
    
        var offset: CGPoint = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
        boundsCenter.y - self.bounds.size.height / 2.0)
        
        let maxOffset: CGPoint = self.maximumContentOffset()
        let minOffset: CGPoint = self.minimumContentOffset()
        offset.x = max(minOffset.x, min(maxOffset.x, offset.x))
        offset.y = max(minOffset.y, min(maxOffset.y, offset.y))
        self.contentOffset = offset
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 2.0
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        if (self.didEndZoomingBlock != nil) {
            self.didEndZoomingBlock(isZoomed)
        }
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.photo?.view.frame = self.centerFrame()
        if (self.didZoomBlock != nil) {
            self.didZoomBlock(isZoomed)
        }
    }
    
    func addGestures() {
        doubleTapGesture = UITapGestureRecognizer(target: self, action: "didDoubleTap:")
        doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: "didSingleTap:")
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        self.addGestureRecognizer(singleTapGesture)
    }
    
    func didDoubleTap(gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.locationInView(self)
        self.handleDoubleTap(tapLocation)
    }
    
    func didSingleTap(gesture: UITapGestureRecognizer) {
        self.handleSingleTap()
    }
    
    func imageNode(imageNode: ASNetworkImageNode!, didLoadImage image: UIImage!) {
        let deviceOrientation = UIDevice.currentDevice().orientation
        let isPortrait = deviceOrientation.isPortrait || !deviceOrientation.isValidInterfaceOrientation || deviceOrientation.isFlat
        let bounds = UIScreen.mainScreen().bounds
        let size = isPortrait ? image.sizeWithWidth(bounds.width) : image.sizeWithHeight(bounds.height)
        let rect = CGRectMake(0.0, 0.0, size.width, size.height)
        imageNode.frame = rect
        imageNode.frame = self.centerFrame()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.contentSize = size
        })
    }
    
}
