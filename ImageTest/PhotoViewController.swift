import Foundation
import UIKit
import AsyncDisplayKit
import pop

class PhotoViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private var chromeViewShowing: Bool = true
    
    let scrollView = ImageScrollView()
    var photo = ASNetworkImageNode()
    let dismissButton = ASButtonNode()
    var index: Int = 0
    var viewToggleBlock: ((Bool) -> Void)!
    var transitionDelegate: ImageransitioningDelegate?
    
    private var imageViewOriginalView: UIView?
    private var originalFrameRelativeToScreen: CGRect = CGRectZero
    private var imageViewFrameInWindow: CGRect = CGRectZero
    private var panOrigin: CGPoint = CGPointZero
    private var isAnimating: Bool = false
    
    init(imageView: ASNetworkImageNode?) {
        super.init(nibName: nil, bundle: nil)
        
        if let image = imageView {
            self.imageViewOriginalView = image.view.superview
            self.photo = image
            self.addPanGesture()
        }

    }
    
    convenience init() {
        self.init(imageView: nil)
    }
    
    init(imageURL: NSURL) {
        super.init(nibName: nil, bundle: nil)
        self.photo.placeholderColor = UIColor.whiteColor()
        self.photo.URL = imageURL
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var text: (caption: String?, credit: String?)?

    var image: UIImage? {
        get {
            return self.photo.image
        }
        set(newImage) {
            self.photo.image = newImage
        }
    }
    
    var photoIsZoomedOutProgress: CGFloat = 0.0 {
        didSet {
            let opacity: CGFloat = PhotoViewController.POPTransition(self.photoIsZoomedOutProgress, 1.0, 0.0)
            self.dismissButton.layer.opacity = Float(opacity)
        }
    }
    
    func setImageFrameInCurrentCoordinate() {
        if self.imageViewOriginalView == nil {
            return
        }
        var newRect: CGRect = self.photo.view.convertRect(self.imageViewOriginalView!.bounds, fromView: self.imageViewOriginalView)
        newRect.size = self.photo.frame.size
        newRect.origin.x = abs(newRect.origin.x)
        newRect.origin.y = abs(newRect.origin.y)
        self.originalFrameRelativeToScreen = newRect
        
        var imageFrameRelativeToWindow: CGRect = self.photo.view.convertRect(UIScreen.mainScreen().bounds, fromView: nil)
        imageFrameRelativeToWindow.size = self.photo.frame.size
        imageFrameRelativeToWindow.origin.x = abs(imageFrameRelativeToWindow.origin.x)
        imageFrameRelativeToWindow.origin.y = abs(imageFrameRelativeToWindow.origin.y)
        self.imageViewFrameInWindow = imageFrameRelativeToWindow
    }

    
    class func POPTransition(progress: CGFloat, _ startValue: CGFloat, _ endValue: CGFloat) -> CGFloat {
        return startValue + (progress * (endValue - startValue))
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
                let view = UIView(frame: UIScreen.mainScreen().bounds)
                view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                self.view = view
        
//                self.setImageFrameInCurrentCoordinate()
        
                self.view.addSubview(self.scrollView)
        
            self.configureScrollView()
               self.onZoomAction()
                self.scrollView.showImageView(self.photo)
    }
    
    func onZoomAction() {
        self.scrollView.didEndZoomingBlock = {(isZoomed: Bool) -> Void in
            self.toggleChromeView(isZoomed)
        }
        
        self.scrollView.handleSingleTapBlock = {() -> Void in
            self.toggleChromeView(!self.chromeViewShowing)
        }
        
    }
    
    func addDismissbutton() {
        dismissButton.frame = CGRectMake(self.view.bounds.maxX - 58.0, 10.0, 44.0, 44.0)
        dismissButton.addTarget(self, action: "dismiss:", forControlEvents: .TouchUpInside)
        dismissButton.backgroundColor = UIColor.whiteColor()
        self.view.addSubnode(dismissButton)
    }
    
    func dismiss(button: UIButton!) {
        self.setStatusBarHidden(false)
        self.toggleChromeView(true)
        self.dismissViewController()
    }
    
    func configureScrollView() {
        self.scrollView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.scrollView.backgroundColor = UIColor.blackColor()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.scrollView.frame = self.view.bounds
        self.dismissButton.measureWithSizeRange(ASSizeRange(min: self.dismissButton.frame.size, max: self.dismissButton.frame.size))
    }
    
    func toggleChromeView(show: Bool) {
        if (viewToggleBlock != nil) {
            viewToggleBlock(show)
        }
        
        var animation: AnyObject! = self.pop_animationForKey("photoIsZoomedOut")
        if (animation == nil) {
            animation = POPSpringAnimation()
            (animation as! POPSpringAnimation).delegate = self
            (animation as! POPSpringAnimation).springBounciness = 5
            (animation as! POPSpringAnimation).springSpeed = 10
            
            let property = POPAnimatableProperty.propertyWithName("photoIsZoomedOutProgress",
                initializer: { (prop: POPMutableAnimatableProperty!) -> Void in
                    prop.readBlock = {(obj: AnyObject!, values: UnsafeMutablePointer<CGFloat>) -> Void in
                        values[0] = (obj as! PhotoViewController).photoIsZoomedOutProgress
                    }
                    
                    prop.writeBlock = {(obj: AnyObject!, values: UnsafePointer<CGFloat>) -> Void in
                        (obj as! PhotoViewController).photoIsZoomedOutProgress = values[0]
                    }
                    
                    prop.threshold = 0.001
                    
            }) as! POPAnimatableProperty
            
            
            (animation as! POPSpringAnimation).property = property
            self.pop_addAnimation((animation as! POPSpringAnimation), forKey: "photoIsZoomedOut")
        }
        
        (animation as! POPSpringAnimation).toValue = show ? 1.0 : 0.0
        
        self.chromeViewShowing = show
    }
    
    func appropriateFrameForImageSize(imageSize: CGSize) -> CGRect {
        if (self.view == nil) {
            return CGRectZero
        }

        let boundSize: CGSize = self.view.bounds.size
        var frame: CGRect = self.photo.frame
        
        let aspect: CGFloat = imageSize.width / imageSize.height
        
        if (boundSize.width / aspect <= boundSize.height) {
            frame.size = CGSizeMake(boundSize.width, boundSize.width / aspect)
        }
        else {
            frame.size = CGSizeMake(boundSize.height * aspect, boundSize.height)
        }
    
        return frame
    }
    
    func centerFrameWithRect(rectToCenter: CGRect) -> CGRect {
        let boundSize: CGSize = self.view.bounds.size
        var frameToCenter = rectToCenter
    
        if (frameToCenter.size.width < boundSize.width) {
            frameToCenter.origin.x = floor((boundSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0.0
        }
    
        if (frameToCenter.size.height < boundSize.height) {
            frameToCenter.origin.y = (boundSize.height - frameToCenter.size.height) / 2.0
        } else {
            frameToCenter.origin.y = 0.0
        }
        return frameToCenter
    }
    
    func presentFromRootViewController(imageView: ASNetworkImageNode) {
        photo.image = imageView.image
        self.addDismissbutton()
       
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        transitionDelegate = ImageransitioningDelegate(image: imageView)
        self.transitioningDelegate = transitionDelegate
        self.modalPresentationStyle = .Custom
        
        appDelegate!.topViewController()!.presentViewController(self, animated: true, completion: nil)

//        self.photo.bounds.size = self.imageViewFrameInWindow.size
//        self.photo.position = self.imageViewFrameInWindow.center
//
//        self.scrollView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
//        self.setStatusBarHidden(true)
    }
    
    func dismissViewController() {
//        debugPrint("Navigation \(self.presentingViewController.topvi)")
//        if let viewController = self.presentingViewController as? UINavigationController {
//            viewController.dismissViewControllerAnimated(true, completion: nil)
//        }
        self.removePanGesture()
        self.dismissViewControllerAnimated(true, completion: nil)


//        self.toggleTransition(false, completionBlock: { (animation: POPAnimation!, finished: Bool) -> Void in
//            self.removePanGesture()
//            self.photo.setupPhotoViewer()
//            self.dismissViewControllerAnimated(true, completion: nil)
//        })
    }
    
    //MARK: Gesture handling
    var panGesture: UIPanGestureRecognizer = {
        let gesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
        gesture.cancelsTouchesInView = true
        return gesture
    }()
    
    func addPanGesture() {
        self.panGesture.addTarget(self, action: "didPan:")
        self.panGesture.delegate = self
        self.photo.view.addGestureRecognizer(self.panGesture)
        self.panGesture.requireGestureRecognizerToFail(self.scrollView.singleTapGesture)
    }
    
    func removePanGesture() {
        self.photo.view.removeGestureRecognizer(self.panGesture)
    }

    func rollbackViewController() {
        self.isAnimating = true
        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.AllowAnimatedContent, animations: { () -> Void in
                self.photo.bounds.size = self.scrollView.centerFrame().size
                self.photo.position = self.scrollView.centerFrame().center
            
                self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(1.0)
            }) { (finished: Bool) -> Void in
                self.isAnimating = false
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        self.panOrigin = self.photo.position
        return !self.isAnimating
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.toggleChromeView(true)
        return true
    }
    
    func didPan(gesture: UIPanGestureRecognizer!) {
        if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
            return
        }
        
        if UIDevice.currentDevice().orientation != .Portrait {
            self.dismissViewController()
        }
        
        self.setStatusBarHidden(false)
        
        let windowSize: CGSize = scrollView.bounds.size
        let currentPoint: CGPoint = gesture.translationInView(self.scrollView)
        let y: CGFloat = currentPoint.y + self.panOrigin.y
        let x: CGFloat = currentPoint.x + self.panOrigin.x

        let position = CGPointMake(x, y)
        self.photo.position = position
        
        let yDiff: CGFloat = abs((y + self.photo.view.frame.size.height/2) - windowSize.height/2)
        let alpha: CGFloat = max(1 - yDiff/(windowSize.height/2), 0.5)
        
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(alpha)
        self.scrollView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(alpha)
        if (gesture.state == .Ended || gesture.state == .Cancelled) {
            if alpha < 0.7 {
                self.dismissViewController()
            } else {
                self.setStatusBarHidden(true)
                self.toggleChromeView(false)
                self.rollbackViewController()
            }
        }
    }
    
    func setStatusBarHidden(hidden: Bool) {
        UIApplication.sharedApplication().setStatusBarHidden(hidden, withAnimation: .Fade)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
        
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return self.isBeingPresented() ? .Portrait : .AllButUpsideDown
    }

    override func shouldAutorotate() -> Bool {
        return !self.isBeingPresented()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
  
        
        let isPortrait = size.height > size.width
        let newSize = isPortrait ? self.photo.image!.size.sizeWithWidth(size.width) : self.photo.image!.size.sizeWithHeight(size.height)
        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            UIView.animateWithDuration(context.transitionDuration(), animations: { () -> Void in
                self.photo.view.bounds.size = newSize
                let position = self.scrollView.centerFrame().center
                self.photo.position = position
            })
        }){ (UIViewControllerTransitionCoordinatorContext) -> Void in
        }
    }
}




