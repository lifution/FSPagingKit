//
//  _FSQueuingScrollView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

class _FSQueuingScrollView: UIScrollView {
    
    enum NavigationDirection {
        case forward
        case reverse
    }
    
    private enum ScrollDirection {
        /// 内容向左滑动（右边有新内容出现）
        case left
        /// 内容向右滑动（左边有新内容出现）
        case right
        /// 停止
        case stop
    }
    
    // MARK: Properties/Internal
    
    weak var dataSource: _FSQueuingScrollViewDataSource?
    
    weak var scrollDelegate: _FSQueuingScrollViewScrollDelegate?
    
    weak var appearanceDelegate: _FSQueuingScrollViewAppearanceDelegate?
    
    weak var gestureRecognizerDelegate: _FSQueuingScrollViewGestureRecognizerDelegate?
    
    // MARK: Properties/Private
    
    private let containerView = UIView()
    
    private var visibleViews: [UIView] = []
    
    /// 临时标记的待显示 view。
    ///
    /// * viewSize 有效(即 `!= .zero`)之前，如果调用 `setView(_:direction:animated:completion:)`
    ///   设置了 view，则不应该把该 view 添加到 visibleViews 之中，应该先使用 tempVisibleView 标记，
    ///   等 viewSize 有效之后，再迁移到 visibleViews 中。 因为 viewSize 无效的话无法确定 view 的 size，所以会影响到布局。
    ///
    /// * 当调用 `setView(_:direction:animated:completion:)` 方法时，animated 为 false 也同样先用 tempVisibleView 标记,
    ///   待 `p_tileViews(in:)` 中再做替换。
    ///
    private var tempVisibleView: UIView?
    
    private var viewSize: CGSize = .zero
    
    /// 调用方法 `setView(_:direction:animated:completion:)` 插入的 view。
    private var insertingView: UIView?
    
    private weak var centerView: UIView?
    
    /// 方法 `setView(_:direction:animated:completion:)` 中的 completion 参数。
    /// 该 closure 在生命周期中只有一次调用，用完即弃。
    private var setViewCompletion: (() -> Void)?
    
    /// 内容滑动方向。
    private var scrollDirection: _FSQueuingScrollView.ScrollDirection = .stop
    
    // MARK: Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        p_didInitialize()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }
}

// MARK: - Override

extension _FSQueuingScrollView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if viewSize != bounds.size {
            viewSize = bounds.size
            contentSize = CGSize(width: viewSize.width * 3, height: viewSize.height)
            containerView.frame = .init(origin: .zero, size: contentSize)
            if !visibleViews.isEmpty {
                for (index, view) in visibleViews.enumerated() {
                    view.frame.size = viewSize
                    view.frame.origin.y = 0.0
                    view.frame.origin.x = viewSize.width * CGFloat(index)
                }
                contentOffset.x = 0.0
            }
        }
        do {
            p_recenterIfNecessary()
        }
        do {
            let visibleBounds = convert(bounds, to: containerView)
            p_tileViews(in: visibleBounds)
        }
    }
}

// MARK: - Private

private extension _FSQueuingScrollView {
    
    /// Invoked after initialization.
    func p_didInitialize() {
        do {
            bounces = false
            delegate = self
            scrollsToTop = false
            clipsToBounds = true
            isPagingEnabled = true
            backgroundColor = .clear
            isExclusiveTouch = true
            decelerationRate = .fast
            keyboardDismissMode = .onDrag
            showsVerticalScrollIndicator = false
            showsHorizontalScrollIndicator = false
            if #available(iOS 11.0, *) {
                contentInsetAdjustmentBehavior = .never
            }
        }
        do {
            addSubview(containerView)
        }
    }
    
    func p_removeAll() {
        visibleViews.forEach { (view) in
            p_viewWillDisappear(view, animated: false)
            p_viewDidDisappear(view)
            p_viewWillMoveToSuperview(view, newSuperview: nil)
            view.removeFromSuperview()
            p_viewDidMoveToSuperview(view)
        }
        visibleViews.removeAll()
        centerView = nil
        insertingView = nil
        tempVisibleView = nil
        setViewCompletion = nil
    }
    
    func p_recenterIfNecessary() {
        let append: CGFloat? = {
            let offsetX = contentOffset.x
            if offsetX > viewSize.width * 1.5 {
                return -viewSize.width
            }
            if offsetX < viewSize.width * 0.5 {
                return viewSize.width
            }
            return nil
        }()
        if let append = append {
            contentOffset.x += append
            visibleViews.forEach { $0.center.x += append }
        }
    }
    
    func p_tileViews(in rect: CGRect) {
        
        let oldVisibleViews = visibleViews
        
        defer {
            // In this moment, visibleViews's count is always less than or equal to 2.
            if visibleViews.count == 1 {
                if oldVisibleViews.count > 1,
                   let disappearedView = oldVisibleViews.filter({ !visibleViews.contains($0) }).first
                {
                    let fromView = disappearedView
                    let toView = visibleViews.first!
                    p_visibleViewChange(from: fromView, to: toView, progress: 1.0)
                } else {
                    p_visibleViewChange(from: nil, to: visibleViews.first!, progress: 1.0)
                }
            }
            if visibleViews.count > 1,
               oldVisibleViews.count > 1,
               let disappearedView = oldVisibleViews.filter({ !visibleViews.contains($0) }).first,
               let appearedView = oldVisibleViews.filter({ disappearedView !== $0 }).first
            {
                p_visibleViewChange(from: disappearedView, to: appearedView, progress: 1.0)
            }
            if visibleViews.count > 1,
               let fromView = visibleViews.filter({ centerView === $0 }).first,
               let toView = visibleViews.filter({ fromView !== $0 }).first
            {
                if oldVisibleViews != visibleViews {
                    p_visibleViewChange(from: fromView, to: toView, progress: 0.0)
                } else {
                    let visibleWidth = toView.frame.intersection(rect).width
                    let progress = visibleWidth / toView.frame.width
                    p_visibleViewChange(from: fromView, to: toView, progress: max(0.0, min(1.0, progress)))
                }
            }
        }
        
        let minimumVisibleX = rect.minX
        let maximumVisibleX = rect.maxX
        
        /// 参考 tempVisibleView 注释。
        if let view = tempVisibleView, viewSize != .zero {
            
            tempVisibleView = nil
            
            // 调用 `setView(_:direction:animated:completion:)` 方法无动画切换页面，
            // 需先清除旧的 visibleViews。
            if !visibleViews.isEmpty {
                visibleViews.forEach { (view) in
                    p_viewWillDisappear(view, animated: false)
                    p_viewDidDisappear(view)
                    p_viewWillMoveToSuperview(view, newSuperview: nil)
                    view.removeFromSuperview()
                    p_viewDidMoveToSuperview(view)
                }
                visibleViews.removeAll()
            }
            
            centerView = view
            visibleViews.append(view)
            
            view.frame.size = viewSize
            view.frame.origin.y = 0.0
            view.frame.origin.x = minimumVisibleX
            
            p_viewWillMoveToSuperview(view, newSuperview: self)
            containerView.addSubview(view)
            p_viewDidMoveToSuperview(view)
            
            p_viewWillAppear(view, animated: false)
            p_viewDidAppear(view)
            
            return
        }
        
        guard !visibleViews.isEmpty, viewSize != .zero else {
            return
        }
        
        var leftInsertingView: UIView?
        var rightInsertingView: UIView?
        var leftRemovingView: UIView?
        var rightRemovingView: UIView?
        
        if let first = visibleViews.first {
            let leftEdge = first.frame.minX
            if leftEdge > minimumVisibleX {
                let newView: UIView? = {
                    if let view = insertingView {
                        return view
                    }
                    return dataSource?.queuingScrollView(self, viewBefore: first)
                }()
                if let view = newView {
                    do {
                        view.frame.size = viewSize
                        view.frame.origin.y = 0.0
                        view.frame.origin.x = leftEdge - view.frame.width
                        
                        leftInsertingView = view
                    }
                } else {
                    let offset = CGPoint(x: viewSize.width, y: contentOffset.y)
                    setContentOffset(offset, animated: false)
                }
            }
        }
        
        if let last = visibleViews.last {
            let rightEdge = last.frame.maxX
            if rightEdge < maximumVisibleX {
                let newView: UIView? = {
                    if let view = insertingView {
                        return view
                    }
                    return dataSource?.queuingScrollView(self, viewAfter: last)
                }()
                if let view = newView {
                    do {
                        view.frame.size = viewSize
                        view.frame.origin.y = 0.0
                        view.frame.origin.x = rightEdge
                        
                        rightInsertingView = view
                    }
                } else {
                    let offset = CGPoint(x: viewSize.width, y: contentOffset.y)
                    setContentOffset(offset, animated: false)
                }
            }
        }
        
        if let first = visibleViews.first, first.frame.maxX <= minimumVisibleX {
            leftRemovingView = first
        }
        
        if let last = visibleViews.last, last.frame.minX >= maximumVisibleX {
            rightRemovingView = last
        }
        
        do {
            if let view = rightInsertingView {
                if let removingView = leftRemovingView {
                    if let oldLast = visibleViews.last, oldLast !== removingView {
                        if removingView.state == .appearing {
                            p_viewWillAppear(oldLast, animated: false)
                        }
                        p_viewDidAppear(oldLast)
                    }
                    if removingView.state == .appearing {
                        p_viewWillDisappear(removingView, animated: false)
                    }
                    p_viewDidDisappear(removingView)
                    
                    p_viewWillMoveToSuperview(removingView, newSuperview: nil)
                    removingView.removeFromSuperview()
                    p_viewDidMoveToSuperview(removingView)
                    visibleViews.removeFirst()
                    
                    leftRemovingView = nil
                }
                
                visibleViews.append(view)
                p_viewWillMoveToSuperview(view, newSuperview: self)
                containerView.addSubview(view)
                p_viewDidMoveToSuperview(view)
                
                p_viewWillAppear(view, animated: true)
                if let willDisappear = visibleViews.first {
                    p_viewWillDisappear(willDisappear, animated: true)
                }
            }
            
            if let view = leftInsertingView {
                if let removingView = rightRemovingView {
                    if let oldFirst = visibleViews.first, oldFirst !== removingView {
                        if removingView.state == .appearing {
                            p_viewWillAppear(oldFirst, animated: false)
                        }
                        p_viewDidAppear(oldFirst)
                    }
                    if removingView.state == .appearing {
                        p_viewWillDisappear(removingView, animated: false)
                    }
                    p_viewDidDisappear(removingView)
                    
                    p_viewWillMoveToSuperview(removingView, newSuperview: nil)
                    removingView.removeFromSuperview()
                    p_viewDidMoveToSuperview(removingView)
                    visibleViews.removeLast()
                    
                    rightRemovingView = nil
                }
                
                visibleViews.insert(view, at: 0)
                p_viewWillMoveToSuperview(view, newSuperview: self)
                containerView.addSubview(view)
                p_viewDidMoveToSuperview(view)
                
                p_viewWillAppear(view, animated: true)
                if let willDisappear = visibleViews.last {
                    p_viewWillDisappear(willDisappear, animated: true)
                }
            }
            
            if let view = leftRemovingView {
                
                let next: UIView? = {
                    if let next = visibleViews.last, next !== view {
                        return next
                    }
                    return nil
                }()
                
                if view.state == .appearing {
                    if let next = next {
                        p_viewWillAppear(next, animated: false)
                        p_viewDidAppear(next)
                    }
                    p_viewWillDisappear(view, animated: false)
                    p_viewDidDisappear(view)
                } else {
                    if let next = next {
                        p_viewDidAppear(next)
                    }
                    p_viewDidDisappear(view)
                }
                
                p_viewWillMoveToSuperview(view, newSuperview: nil)
                view.removeFromSuperview()
                p_viewDidMoveToSuperview(view)
                visibleViews.removeFirst()
            }
            
            if let view = rightRemovingView {
                
                let previous: UIView? = {
                    if let previous = visibleViews.first, previous !== view {
                        return previous
                    }
                    return nil
                }()
                
                if view.state == .appearing {
                    if let previous = previous {
                        p_viewWillAppear(previous, animated: false)
                        p_viewDidAppear(previous)
                    }
                    p_viewWillDisappear(view, animated: false)
                    p_viewDidDisappear(view)
                } else {
                    if let previous = previous {
                        p_viewDidAppear(previous)
                    }
                    p_viewDidDisappear(view)
                }
                
                p_viewWillMoveToSuperview(view, newSuperview: nil)
                view.removeFromSuperview()
                p_viewDidMoveToSuperview(view)
                visibleViews.removeLast()
            }
        }
    }
}

// MARK: - Appearance Cycle

private extension _FSQueuingScrollView {
    
    func p_viewWillMoveToSuperview(_ view: UIView, newSuperview: UIView?) {
        appearanceDelegate?.viewWillMoveToSuperview(view, newSuperview: newSuperview)
    }
    
    func p_viewDidMoveToSuperview(_ view: UIView) {
        if view.superview == nil {
            view.state = .unmounted
        }
        appearanceDelegate?.viewDidMoveToSuperview(view)
    }
    
    func p_viewWillAppear(_ view: UIView, animated: Bool) {
        view.state = .appearing
        appearanceDelegate?.viewWillAppear(view, animated: animated)
    }
    
    func p_viewDidAppear(_ view: UIView) {
        
        centerView = view
        view.state = .appeared
        
        appearanceDelegate?.viewDidAppear(view)
        
        if insertingView === view {
            setViewCompletion?()
            insertingView = nil
            panGestureRecognizer.isEnabled = true
        }
        setViewCompletion = nil
    }
    
    func p_viewWillDisappear(_ view: UIView, animated: Bool) {
        view.state = .disappearing
        appearanceDelegate?.viewWillDisappear(view, animated: animated)
    }
    
    func p_viewDidDisappear(_ view: UIView) {
        view.state = .disappeared
        appearanceDelegate?.viewDidDisappear(view)
    }
    
    func p_visibleViewChange(from fromView: UIView?, to toView: UIView, progress: CGFloat) {
        appearanceDelegate?.visibleViewChange(from: fromView, to: toView, progress: progress)
    }
}

// MARK: - UIScrollViewDelegate

extension _FSQueuingScrollView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        do {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
            if velocity.x > 0.0 {
                scrollDirection = .right
            } else if velocity.x < 0.0 {
                scrollDirection = .left
            } else {
                scrollDirection = .stop
            }
        }
        do {
            scrollDelegate?.queuingScrollViewWillBeginDragging(self)
        }
    }
    
    /// 很奇怪的一件事，当没有下一页时，把 scrollView 固定居中，滑动后总会反弹，
    /// 但当 delegate 实现该方法后，反弹的问题就解决了，玄学问题，至今未得知原由。
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        do {
            if targetContentOffset.pointee.x > scrollView.contentOffset.x {
                scrollDirection = .left
            } else if targetContentOffset.pointee.x < scrollView.contentOffset.x {
                scrollDirection = .right
            } else {
                scrollDirection = .stop
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollDelegate?.queuingScrollViewDidEndDragging(self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        do {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
            if velocity.x > 0.0 {
                scrollDirection = .right
            } else if velocity.x < 0.0 {
                scrollDirection = .left
            } else {
                scrollDirection = .stop
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension _FSQueuingScrollView: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            if visibleViews.count == 0 {
                return false
            }
            if let delegate = gestureRecognizerDelegate {
                return delegate.queuingScrollView(self, panGestureRecognizerShouldBegin: panGestureRecognizer)
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let delegate = gestureRecognizerDelegate {
            return delegate.queuingScrollView(self, gestureRecognizer: gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let delegate = gestureRecognizerDelegate {
            return delegate.queuingScrollView(self, gestureRecognizer: gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer)
        }
        return false
    }
}

// MARK: - Internal

extension _FSQueuingScrollView {
    
    func setView(_ view: UIView?, direction: _FSQueuingScrollView.NavigationDirection, animated: Bool, completion: (() -> Void)? = nil) {
        
        setViewCompletion = nil
        
        guard let view = view else {
            p_removeAll()
            completion?()
            return
        }
        
        // 要切换的 view 就是当前所显示的 view，直接返回。
        if visibleViews.contains(view) {
            completion?()
            return
        }
        
        insertingView = view
        setViewCompletion = completion
        
        guard
            viewSize != .zero,
            !visibleViews.isEmpty,
            animated
        else {
            // 1、还未布局
            // 2、这是首个被添加的 view
            // 3、不需要动画的切换
            // 凡是这三种情况，都是先记录，然后在下一个 update cycle 中直接替换为 visibleView。
            // 此时忽略 direction 和 animated 参数。
            tempVisibleView = view
            setNeedsLayout()
            return
        }
        
        // 动画切换过程中禁止手势，以免手势影响切换过程。
        // 在 `p_viewDidAppear(_:animated:)` 中会重新开启。
        panGestureRecognizer.isEnabled = false
        
        scrollDirection = direction == .forward ? .left : .right
        
        var contentOffset = self.contentOffset
        contentOffset.x = (direction == .forward ? viewSize.width * 2 : 0.0)
        setContentOffset(contentOffset, animated: true)
    }
    
    func removeAll() {
        p_removeAll()
    }
}


// MARK: - UIView Appearance Extension

private extension UIView {
    
    private static var key = 0
    
    enum AppearanceState: Int {
        case unmounted    = 0
        case appearing    = 1
        case appeared     = 2
        case disappearing = 3
        case disappeared  = 4
    }
    
    var state: AppearanceState {
        get {
            if let stateValue = objc_getAssociatedObject(self, &UIView.key) as? Int,
               let state = AppearanceState(rawValue: stateValue)
            {
                return state
            }
            return .unmounted
        }
        set {
            objc_setAssociatedObject(self, &UIView.key, newValue.rawValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
