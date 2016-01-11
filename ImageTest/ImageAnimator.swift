//
//  ImageAnimator.swift
//  ImageTest
//
//  Created by Rajinder Ramgarhia on 2016-01-09.
//  Copyright © 2016 Test. All rights reserved.
//

import pop
import AsyncDisplayKit

class ImageAnimator:  NSObject, UIViewControllerAnimatedTransitioning {
    var viewInProgress: CGFloat = 0.0
    
    var imageOriginalRect = CGRectZero
    var currentImageRect = CGRectZero
    
    var isPresentation: Bool?
    weak var imageView: ASNetworkImageNode?
    weak var toView: UIView?
    
    override init() {
        super.init()
    }
    
    convenience init(image: ASNetworkImageNode) {
        self.init()
        
        imageView = image
        
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController: UIViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController: UIViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!


        let containerView: UIView = transitionContext.containerView()!
        
        let animatingViewController: UIViewController = self.isPresentation! ? toViewController : fromViewController
        let animatingView = animatingViewController.view
        
        let appearedFrame = transitionContext.finalFrameForViewController(animatingViewController)
        let dismissedFrame: CGRect = CGRectMake(0.0, 0.0, appearedFrame.width, appearedFrame.height)
        
        let frame = self.isPresentation! ? dismissedFrame : appearedFrame
        
        animatingView.frame = frame
        
        imageOriginalRect = (imageView?.view.convertRect(imageView!.bounds, toView: UIApplication.sharedApplication().windows[0]))!
        
        toView = transitionContext.viewForKey(UITransitionContextToViewKey)

        if let photoViewController = toViewController as? PhotoViewController {
            // Presenting
            UIView.performWithoutAnimation {
                self.imageView?.hidden = true
                toViewController.view.alpha = 0
                containerView.addSubview(self.toView!)
            }

            if !(imageOriginalRect.isInfinite) {
                photoViewController.photo.frame = imageOriginalRect
                let rect = self.appropriateFrameForImageSize(photoViewController.photo.image!.size)
                let newImageViewFrame: CGRect = photoViewController.centerFrameWithRect(rect)
                
                let animation: POPSpringAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
                animation.beginTime = CACurrentMediaTime()
                
                animation.fromValue = NSValue(CGRect: photoViewController.photo.frame)
                animation.toValue = NSValue(CGRect: newImageViewFrame)
                photoViewController.photo.view.pop_addAnimation(animation, forKey: "imageFrame")
                
            }
        } else if let photoViewController = fromViewController as? PhotoViewController{
           // Dismissing
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
            
            UIView.performWithoutAnimation {
                toViewController.view.alpha = 1
                containerView.insertSubview(toViewController.view, belowSubview: fromView)
            }
            

            let animation: POPSpringAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
            animation.beginTime = CACurrentMediaTime()
            
            animation.fromValue = NSValue(CGRect: photoViewController.photo.frame)
            animation.toValue = NSValue(CGRect: imageOriginalRect)
            photoViewController.photo.view.pop_addAnimation(animation, forKey: "imageFrame")
        }
        
        var animation: AnyObject! = self.pop_animationForKey("showImage")
        if (animation == nil) {
            animation = POPSpringAnimation()
            (animation as! POPSpringAnimation).delegate = self
            
            let property = POPAnimatableProperty.propertyWithName("showImage",
                initializer: { (prop: POPMutableAnimatableProperty!) -> Void in
                    prop.readBlock = {(obj: AnyObject!, values: UnsafeMutablePointer<CGFloat>) -> Void in
                        values[0] = (obj as! ImageAnimator).viewInProgress
                    }
                    
                    prop.writeBlock = {(obj: AnyObject!, values: UnsafePointer<CGFloat>) -> Void in
                        (obj as! ImageAnimator).viewInProgress = values[0]
                       
                        let opacity: CGFloat = PhotoViewController.POPTransition(self.viewInProgress, 0.0, 1.0)
                        if self.isPresentation! {
                            animatingView.alpha = opacity
                        } else {
                            let opacity: CGFloat = PhotoViewController.POPTransition(self.viewInProgress, 1.0, 0.0)
                            if let photoViewController = fromViewController as? PhotoViewController{
                                photoViewController.scrollView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(opacity)

                            }
                        }
                        
                    }
                    
                    prop.threshold = 0.001
                    
            }) as! POPAnimatableProperty
            
            
            (animation as! POPSpringAnimation).property = property
            (animation as! POPSpringAnimation).completionBlock = {(animation: POPAnimation!, finished: Bool) -> Void in
                            self.imageView?.hidden = self.isPresentation! ? true : false
                            if !(self.isPresentation!) {
                                self.imageView!.setupPhotoViewer()

                            }
                            transitionContext.completeTransition(finished)
                        }

            self.pop_addAnimation((animation as! POPSpringAnimation), forKey: "showImage")
        }
        
        (animation as! POPSpringAnimation).beginTime = CACurrentMediaTime()
        (animation as! POPSpringAnimation).toValue = self.isPresentation! ? 1.0 : 1.0

    }
    
    func appropriateFrameForImageSize(imageSize: CGSize) -> CGRect {
        let boundSize: CGSize = self.toView!.bounds.size
        var frame: CGRect = self.imageView!.frame
        
        let aspect: CGFloat = imageSize.width / imageSize.height
        
        if (boundSize.width / aspect <= boundSize.height) {
            frame.size = CGSizeMake(boundSize.width, boundSize.width / aspect)
        }
        else {
            frame.size = CGSizeMake(boundSize.height * aspect, boundSize.height)
        }
        
        return frame
    }
    
}

class ImageransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    weak var imageView: ASNetworkImageNode?
    
    override init() {
        super.init()
    }
    
    convenience init(image: ASNetworkImageNode) {
        self.init()
        self.imageView = image
        
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        return CustomPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    func animationController() -> ImageAnimator {
        return ImageAnimator(image: imageView!)
    }
    
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let animationController = self.animationController()
        animationController.isPresentation = true
        return animationController
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = self.animationController()
        animationController.isPresentation = false
        return animationController
    }
    
}

class CustomPresentationController : UIPresentationController {
    override func shouldRemovePresentersView() -> Bool {
        return true
    }
    
}
