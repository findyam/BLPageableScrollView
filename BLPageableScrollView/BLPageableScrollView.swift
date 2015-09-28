//
//  BLPageableScrollView.swift
//  BLPageableScrollView
//
//  Created by fuyong on 15/9/11.
//  Copyright © 2015年 FindYAM. All rights reserved.
//

import UIKit

public protocol BLPageableScrollViewDataSource : NSObjectProtocol {
    func numberOfPagesInPageableScrollView(pageableScrollView: BLPageableScrollView) -> Int
    func pageableScrollView(pageableScrollView: BLPageableScrollView, viewAtIndex index:Int) -> UIView
    func pageableScrollView(pageableScrollView: BLPageableScrollView, didSelectAtIndex index:Int)
}

private var BLReusedIdentiferKey: Void?

private extension UIView {
    var bl_reusedIdentifier: String? {
        
        get {
            return objc_getAssociatedObject(self, &BLReusedIdentiferKey) as? String
        }
        
        set {
            objc_setAssociatedObject(self, &BLReusedIdentiferKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

class BLScrollView: UIScrollView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if (((point.x <= -self.frame.width) || point.x >= self.frame.width) && (point.y <= self.frame.height)) {
            return true
        } else {
            return false
        }
    }
}

@IBDesignable

public class BLPageableScrollView: UIView, UIScrollViewDelegate {
    
    lazy var scrollView: BLScrollView! = {
        let scrollView = BLScrollView(frame: CGRectZero)
        scrollView.pagingEnabled = true
        scrollView.backgroundColor = UIColor.yellowColor()
        scrollView.clipsToBounds = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
        }()
    var index: Int = 0;
    weak public var dataSource: BLPageableScrollViewDataSource?
    var timer: NSTimer = {
        let t = NSTimer()
        return t;
        }()
    lazy var duration: NSTimeInterval = {
        return 3.0
    }()
    
    lazy var reuseableClasses: Dictionary<String, AnyClass>! = {
        let dictionary = Dictionary<String, AnyClass>()
        return dictionary;
        }()
    
    lazy var reuseableNibs: Dictionary<String, UINib>! = {
        let dictionary = Dictionary<String, UINib>()
        return dictionary;
    }()
    
    lazy var reusedViews: Dictionary<String, Set<UIView>>! = {
        let dictionary = Dictionary<String, Set<UIView>>()
        return dictionary;
        }()
    
    // MARK: life cycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    // MARK: public methods
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if (self.scrollView != nil) {
            self.scrollView.contentSize = CGSizeMake(5 * self.scrollView.frame.size.width, self.scrollView.frame.size.height)
            self.reloadData()
            self.scrollView.setContentOffset(CGPointMake(2 * self.scrollView.frame.size.width, 0), animated: false)
            self.startTimer()
        }
    }

    
    public func reloadData() {
        if (self.scrollView != nil) {
            
            let numberOfPages: Int? = self.dataSource?.numberOfPagesInPageableScrollView(self);
            if (numberOfPages == nil || numberOfPages == 0) {
                return
            }
            
            for view in self.scrollView.subviews {
                view.removeFromSuperview();
                if view.bl_reusedIdentifier != nil {
                    var reuseSet =  self.reusedViews[view.bl_reusedIdentifier!]
                    reuseSet?.insert(view)
                    for gesture in view.gestureRecognizers! {
                        view.removeGestureRecognizer(gesture)
                    }
                }
            }
            
            let privousIndex: Int = self.validatedIndex(self.index - 1)
            let nextIndex: Int = self.validatedIndex(self.index + 1)
            
            let firstIndex = self.validatedIndex(privousIndex - 1)
            let lastIndex = self.validatedIndex(nextIndex + 1)

            let privousView: UIView! = self.dataSource?.pageableScrollView(self, viewAtIndex: privousIndex)
            privousView.frame = CGRectMake(self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)
            privousView.tag = privousIndex
            self.scrollView.addSubview(privousView)
            self.addGestureForView(privousView)
            
            let currentView: UIView! = self.dataSource?.pageableScrollView(self, viewAtIndex: self.index)
            currentView.frame = CGRectMake(2 * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)
            self.scrollView.addSubview(currentView)
            currentView.tag = self.index
            self.addGestureForView(currentView)
            
            let nextView: UIView! = self.dataSource?.pageableScrollView(self, viewAtIndex: nextIndex)
            nextView.frame = CGRectMake(3 * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)
            self.scrollView.addSubview(nextView)
            nextView.tag = nextIndex
            self.addGestureForView(nextView)
            
            let firstView: UIView! = self.dataSource?.pageableScrollView(self, viewAtIndex: firstIndex)
            firstView.frame = CGRectMake(0, 0, self.scrollView.frame.width, self.scrollView.frame.height)
            self.scrollView.addSubview(firstView)
            firstView.tag = firstIndex
            self.addGestureForView(firstView)
            
            let lastView: UIView! = self.dataSource?.pageableScrollView(self, viewAtIndex: lastIndex)
            lastView.frame = CGRectMake(4 * self.scrollView.frame.width, 0, self.scrollView.frame.width, self.scrollView.frame.height)
            self.scrollView.addSubview(lastView)
            lastView.tag = lastIndex
            self.addGestureForView(lastView)
        }
    }
    
    public func addGestureForView(view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("handleTapGesture:"))
        view.addGestureRecognizer(tapGesture)
    }
    
    public func registerNib(nib: UINib?, forViewReuseIdentifier identifier: String) {
        self.reuseableNibs[identifier] = nib
    }
    
    public func registerClass(reuseClass: AnyClass?, forViewReuseIdentifer identifier: String) {
        self.reuseableClasses[identifier] = reuseClass
    }
    
    public func dequeueReusableViewWithIdentifier(identifier: String) -> UIView? {
        var reuseViewSet: Set<UIView>? = self.reusedViews[identifier]
        let reuseView: UIView? = reuseViewSet?.first
        if reuseView != nil {
            reuseViewSet?.remove(reuseView!)
            return reuseView;
        }
        
        let reuseClass: AnyClass? = self.reuseableClasses[identifier]
        if (reuseClass != nil) {
            let view: UIView! = (reuseClass as! UIView.Type).init(frame: CGRectZero)
            view.bl_reusedIdentifier = identifier
            return view
        }
        
        let reuseNib: UINib? = self.reuseableNibs[identifier]
        if (reuseNib != nil) {
            let view: UIView! = (reuseNib?.instantiateWithOwner(nil, options: nil) as! Array).first
            view.bl_reusedIdentifier = identifier
            return view
        }
        return nil
    }
    

    // MARK: privite methods
    
    func handleTapGesture(sender: UITapGestureRecognizer) {
        self.dataSource?.pageableScrollView(self, didSelectAtIndex: sender.view!.tag)
    }
    
    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.delegate = self
        self.addSubview(self.scrollView)
        let scrollViewTopConstraint = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        let scrollViewCenterXConstraint = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let scrollViewWidthConstraint = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant: 0)
        
        let scrollViewBottomContraint = NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        let scrollViewConstraints = [scrollViewTopConstraint, scrollViewCenterXConstraint, scrollViewWidthConstraint, scrollViewBottomContraint]
        self.addConstraints(scrollViewConstraints)
    }
    
    private func validatedIndex(index: Int) -> Int {
        let numberOfPages: Int! = self.dataSource?.numberOfPagesInPageableScrollView(self)
        
        if (index == -1) {
            return numberOfPages - 1
        }
        
        if (index == numberOfPages) {
            return 0
        }
        return index
    }
    
    func startTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(self.duration, target: self, selector: Selector("runTimer"), userInfo: nil, repeats: true)
    }
    
    func invalidateTimer() {
        self.timer.invalidate()
    }
    
    func runTimer() {
        self.scrollView.setContentOffset(CGPointMake(3 * self.scrollView.frame.width, 0), animated: true)
    }
    
    // MARK: UIScrollViewDelegate method
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let point: CGPoint! = scrollView.contentOffset
        if (point.x >= 3 * scrollView.frame.size.width) {
            self.index = self.validatedIndex(self.index + 1)
            scrollView.setContentOffset(CGPointMake(2 * scrollView.frame.size.width, 0), animated:false)
            self.reloadData()
        }
        if (point.x <= scrollView.frame.size.width) {
            self.index = self.validatedIndex(self.index - 1)
            scrollView.setContentOffset(CGPointMake(2 * scrollView.frame.size.width, 0), animated:false)
            self.reloadData()
        }
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.invalidateTimer()
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.startTimer()
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if (self.scrollView != nil && self.pointInside(point, withEvent: event)) {
            let newPoint = self.convertPoint(point, toView: self.scrollView)
            let view: UIView? = self.scrollView.hitTest(newPoint, withEvent: event)
            if view != nil {
                return view
            } else {
                return self.scrollView
            }
        }
        return super.hitTest(point, withEvent: event)
    }

    
}