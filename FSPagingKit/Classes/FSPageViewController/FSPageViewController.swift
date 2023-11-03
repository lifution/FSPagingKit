//
//  FSPageViewController.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/13.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit
import Foundation

/// FSPageViewController 功能和 UIKit 的 UIPageViewController 一样，
/// 该类可以直接使用，但要实现 dataSource，否则不会显示任何内容。
///
/// - 在平常的开发中，你可以使用已封装好的 FSPagingViewController，该类内部管理着
///   一个 FSPageViewController 并已做了常规的封装，比如显示 titlesView、联动等功能，
///   API 相对于 FSPageViewController 也更适合用在平常开发中。
///
/// - 如果你需要一个更复杂、更自由的 PageViewController，则可以继承 FSPageViewController
///   做自己的需求封装。
///
open class FSPageViewController: UIViewController {
    
    // MARK: NavigationDirection
    
    public enum NavigationDirection {
        case forward
        case reverse
    }
    
    // MARK: Properties/Public
    
    public weak var delegate: FSPageViewControllerDelegate?
    
    public weak var dataSource: FSPageViewControllerDataSource?
    
    public weak var gestureRecognizerDelegate: FSPageViewControllerGestureRecognizerDelegate?
    
    // MARK: Properties/Private
    
    private lazy var scrollView: _FSQueuingScrollView = {
        let view = _FSQueuingScrollView()
        view.dataSource = self
        view.scrollDelegate = self
        view.appearanceDelegate = self
        view.gestureRecognizerDelegate = self
        return view
    }()
    
    private let viewControllersMap = NSMapTable<UIView, UIViewController>.weakToWeakObjects()
    
    private var visibleViewController: UIViewController?
    
    private var appearanceStatus: FSPageViewController.AppearanceStatus = .unmounted
    
    // MARK: Initialization
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        p_didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        p_didInitialize()
    }
    
    /// Invoked after initialization.
    private func p_didInitialize() {
        
    }
}

// MARK: - Life Cycle

extension FSPageViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        p_setupViews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceStatus = .willAppear
        visibleViewController?.beginAppearanceTransition(true, animated: animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appearanceStatus = .didAppear
        visibleViewController?.endAppearanceTransition()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceStatus = .willDisappear
        visibleViewController?.beginAppearanceTransition(false, animated: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        appearanceStatus = .didDisappear
        visibleViewController?.endAppearanceTransition()
    }
}

// MARK: - Override

extension FSPageViewController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        return visibleViewController
    }
    
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return visibleViewController
    }
    
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        return visibleViewController
    }
    
    open override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = .init(origin: .zero, size: view.bounds.size)
    }
}

// MARK: - Private

private extension FSPageViewController {
    
    /// Invoked in the `viewDidLoad` method.
    func p_setupViews() {
        do {
            view.backgroundColor = .white
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
        }
        do {
            view.addSubview(scrollView)
        }
    }
    
    func p_recordViewController(_ viewController: UIViewController, for view: UIView) {
        if let _ = viewControllersMap.object(forKey: view) {
            return
        }
        viewControllersMap.setObject(viewController, forKey: view)
    }
    
    func p_viewController(for view: UIView) -> UIViewController? {
        return viewControllersMap.object(forKey: view)
    }
    
    func p_setNeedsUIUpdate() {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 9.0, *) {
            setNeedsFocusUpdate()
        }
        if #available(iOS 11.0, *) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
            setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        }
    }
    
    func p_setViewController(_ viewController: UIViewController?,
                             direction: FSPageViewController.NavigationDirection,
                             animated: Bool,
                             completion: (() -> Void)? = nil) {
        guard let vc = viewController else {
            p_removeAll()
            completion?()
            return
        }
        p_recordViewController(vc, for: vc.view)
        let d: _FSQueuingScrollView.NavigationDirection = direction == .forward ? .forward : .reverse
        scrollView.setView(vc.view, direction: d, animated: animated, completion: completion)
    }
    
    func p_removeAll() {
        scrollView.removeAll()
        viewControllersMap.removeAllObjects()
        visibleViewController = nil
        p_setNeedsUIUpdate()
    }
}

// MARK: - _FSQueuingScrollViewDataSource

extension FSPageViewController: _FSQueuingScrollViewDataSource {
    
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView, viewBefore view: UIView) -> UIView? {
        guard
            let source = dataSource,
            let currentVC = p_viewController(for: view),
            let targetVC = source.pageViewController(self, viewControllerBefore: currentVC)
        else {
            return nil
        }
        let targetView = targetVC.view!
        p_recordViewController(targetVC, for: targetView)
        return targetView
    }
    
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView, viewAfter view: UIView) -> UIView? {
        guard
            let source = dataSource,
            let currentVC = p_viewController(for: view),
            let targetVC = source.pageViewController(self, viewControllerAfter: currentVC)
        else {
            return nil
        }
        let targetView = targetVC.view!
        p_recordViewController(targetVC, for: targetView)
        return targetView
    }
}

// MARK: - _FSQueuingScrollViewScrollDelegate

extension FSPageViewController: _FSQueuingScrollViewScrollDelegate {
    
    func queuingScrollViewWillBeginDragging(_ queuingScrollView: _FSQueuingScrollView) {
        delegate?.pageViewControllerWillBeginDragging(self)
    }
    
    func queuingScrollViewDidEndDragging(_ queuingScrollView: _FSQueuingScrollView) {
        delegate?.pageViewControllerDidEndDragging(self)
    }
}

// MARK: - _FSQueuingScrollViewAppearanceDelegate

extension FSPageViewController: _FSQueuingScrollViewAppearanceDelegate {
    
    func viewWillMoveToSuperview(_ view: UIView, newSuperview: UIView?) {
        guard let vc = p_viewController(for: view) else {
            return
        }
        if let _ = newSuperview {
            // 调用 `addChild(_:)` 方法会自动调用 `willMove(toParent:)` 方法。
            addChild(vc)
        } else {
            vc.willMove(toParent: nil)
        }
    }
    
    func viewDidMoveToSuperview(_ view: UIView) {
        guard let vc = p_viewController(for: view) else {
            return
        }
        if let _ = view.superview {
            vc.didMove(toParent: self)
        } else {
            // 调用 `removeFromParent()` 方法会自动调用 `didMove(toParent:)` 方法。
            vc.removeFromParent()
        }
    }
    
    func viewWillAppear(_ view: UIView, animated: Bool) {
        
        guard let vc = p_viewController(for: view) else {
            return
        }
        
        if visibleViewController !== vc {
            visibleViewController = vc
            p_setNeedsUIUpdate()
        }
        
        if appearanceStatus >= .willAppear {
            vc.beginAppearanceTransition(true, animated: animated)
        }
    }
    
    func viewDidAppear(_ view: UIView) {
        guard let vc = p_viewController(for: view) else {
            return
        }
        if appearanceStatus >= .didAppear {
            vc.endAppearanceTransition()
        }
    }
    
    func viewWillDisappear(_ view: UIView, animated: Bool) {
        guard let vc = p_viewController(for: view) else {
            return
        }
        if appearanceStatus < .willDisappear {
            vc.beginAppearanceTransition(false, animated: animated)
        }
    }
    
    func viewDidDisappear(_ view: UIView) {
        guard let vc = p_viewController(for: view) else {
            return
        }
        if appearanceStatus < .didDisappear {
            vc.endAppearanceTransition()
        }
    }
    
    func visibleViewChange(from fromView: UIView?, to toView: UIView, progress: CGFloat) {
        let toVC = p_viewController(for: toView)
        let fromVC: UIViewController? = {
            if let view = fromView {
                return p_viewController(for: view)
            }
            return toVC
        }()
        if progress == 1.0, let to = toVC {
            delegate?.pageViewController(self, didFinishScrollingTo: to)
            return
        }
        if let from = fromVC, let to = toVC {
            if progress == 0.0 {
                delegate?.pageViewController(self, willBeginScrollingFrom: from, to: to)
            } else {
                delegate?.pageViewController(self, isScrollingFrom: from, to: to, progress: progress)
            }
        }
    }
}

// MARK: - _FSQueuingScrollViewGestureRecognizerDelegate

extension FSPageViewController: _FSQueuingScrollViewGestureRecognizerDelegate {
    
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let delegate = gestureRecognizerDelegate {
            return delegate.pageViewController(self, gestureRecognizer: gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
        }
        return false
    }
    
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let delegate = gestureRecognizerDelegate {
            return delegate.pageViewController(self, gestureRecognizer: gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer)
        }
        return false
    }
    
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        if let delegate = gestureRecognizerDelegate {
            return delegate.pageViewController(self, panGestureRecognizerShouldBegin: panGestureRecognizer)
        }
        return true
    }
}

// MARK: - Public

public extension FSPageViewController {
    
    func setViewController(_ viewController: UIViewController?,
                           direction: FSPageViewController.NavigationDirection,
                           animated: Bool,
                           completion: (() -> Void)? = nil) {
        p_setViewController(viewController, direction: direction, animated: animated, completion: completion)
    }
    
    func removeAll() {
        p_removeAll()
    }
}

// MARK: - Private Defines

private extension FSPageViewController {
    
    enum AppearanceStatus {
        
        case unmounted // 初始化后还未显示过。
        case willAppear
        case didAppear
        case willDisappear
        case didDisappear
        
        private var intValue: Int {
            switch self {
            case .unmounted:
                return 0
            case .willAppear:
                return 1
            case .didAppear:
                return 2
            case .willDisappear:
                return 3
            case .didDisappear:
                return 4
            }
        }
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.intValue < rhs.intValue
        }
        static func <= (lhs: Self, rhs: Self) -> Bool {
            return lhs.intValue <= rhs.intValue
        }
        static func > (lhs: Self, rhs: Self) -> Bool {
            return lhs.intValue > rhs.intValue
        }
        static func >= (lhs: Self, rhs: Self) -> Bool {
            return lhs.intValue >= rhs.intValue
        }
    }
}
