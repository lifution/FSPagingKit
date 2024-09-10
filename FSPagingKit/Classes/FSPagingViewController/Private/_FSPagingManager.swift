//
//  _FSPagingManager.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

final class _FSPagingManager: NSObject {
    
    // MARK: Properties/Internal
    
    weak var pagingDelegate: FSPagingViewControllerDelegate?
    weak var pagingDataSource: FSPagingViewControllerDataSource?
    weak var pagingViewController: FSPagingViewController!
    
    let parentScrollView = _FSPagingNestedScrollView()
    
    let pageViewController = FSPageViewController()
    
    var isInfinite = false
    
    var isPagingEnabled = true
    
    var headerHeight: CGFloat = 0.0 {
        didSet {
            if headerHeight != oldValue {
                p_setNeedsLayoutUpdate()
            }
        }
    }
    
    var stickyHeight: CGFloat = 0.0 {
        didSet {
            if stickyHeight != oldValue {
                p_setNeedsLayoutUpdate()
            }
        }
    }
    
    var contentInset: UIEdgeInsets = .zero {
        didSet {
            if contentInset != oldValue {
                p_setNeedsLayoutUpdate()
            }
        }
    }
    
    var onParentDidScroll: ((CGPoint) -> Void)?
    
    var shouldRecognizeSimultaneously: ((_ gestureRecognizer: UIGestureRecognizer, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool)?
    
    var shouldRequireFailure: ((_ gestureRecognizer: UIGestureRecognizer, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool)?
    
    // MARK: Properties/Private
    
    private var view: UIView {
        return pagingViewController.view!
    }
    
    private var isViewLoaded: Bool {
        return pagingViewController.isViewLoaded
    }
    
    private var pageView: UIView {
        return pageViewController.view!
    }
    
    private var viewSize: CGSize = .zero
    
    private var needsReload = false
    private var needsLayoutUpdate = false
    private var needsPageScrollableUpdate = false
    
    private var currentPage = 0
    private var numberOfPages = 0
    
    private let caches = NSMapTable<UIViewController, _PagingIndex>.weakToStrongObjects()
    
    private var bounces = false
    
    /// 当前页的页状态配置，每次切换页面时都会更新该属性。
    private var config = FSPagingConfig()
    
    /// 每一页中的 scrollView，用于解决垂直方向的滑动冲突。
    private weak var childScrollView: UIScrollView?
    
    private var childOffsetObservation: NSKeyValueObservation?
    
    private var parentOffset: CGPoint = .zero
    private var childOffset: CGPoint = .zero
    
    private var parentScrollDirection: _ScrollDirection = .stop
    
    // MARK: Initialization
    
    override init() {
        super.init()
        parentScrollView.delegate = self
        pageViewController.delegate = self
        pageViewController.dataSource = self
        pageViewController.gestureRecognizerDelegate = self
    }
}

// MARK: - Private

private extension _FSPagingManager {
    
    func p_reset() {
        config = FSPagingConfig()
        currentPage = 0
        numberOfPages = 0
        caches.removeAllObjects()
        p_clearChildObservation()
        p_setNeedsLayoutUpdate()
    }
    
    func p_clearChildObservation() {
        if let scrollView = childScrollView,
           let index = parentScrollView.simultaneouslyGestureRecognizers.firstIndex(of: scrollView.panGestureRecognizer)
        {
            parentScrollView.simultaneouslyGestureRecognizers.remove(at: index)
        }
        childOffset = .zero
        childScrollView = nil
        childOffsetObservation?.invalidate()
        childOffsetObservation = nil
    }
    
    func p_record(_ viewController: UIViewController, at index: Int) {
        if let _ = caches.object(forKey: viewController) {
            return
        }
        let pagingIndex = _PagingIndex(page: index)
        caches.setObject(pagingIndex, forKey: viewController)
    }
    
    func p_viewController(at index: Int) -> UIViewController? {
        if let vcs = caches.keyEnumerator().allObjects as? [UIViewController] {
            for vc in vcs {
                if let pagingIndex = caches.object(forKey: vc), pagingIndex.page == index {
                    return vc
                }
            }
        }
        return nil
    }
    
    func p_scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === parentScrollView {
            p_parentScrollViewDidScroll(scrollView)
        }
        if scrollView === childScrollView {
            p_childScrollViewDidScroll(scrollView)
        }
    }
    
    func p_parentScrollViewDidScroll(_ scrollView: UIScrollView) {
        
        defer {
            if parentOffset != scrollView.contentOffset {
                parentOffset = scrollView.contentOffset
                onParentDidScroll?(parentOffset)
            }
        }
        
        if scrollView.contentOffset.y > parentOffset.y {
            parentScrollDirection = .up
        } else if scrollView.contentOffset.y < parentOffset.y {
            parentScrollDirection = .down
        } else {
            parentScrollDirection = .stop
        }
        
        if stickyHeight < headerHeight, bounces, config.isSticky {
            let parentOffsetY = parentScrollView.contentOffset.y
            let halfStickyHeight = (headerHeight - stickyHeight) / 2.0
            if parentOffsetY >= halfStickyHeight {
                if parentScrollView.bounces {
                    parentScrollView.bounces = false
                }
            } else {
                if !parentScrollView.bounces {
                    parentScrollView.bounces = true
                }
            }
        }
        
        if childScrollView == nil {
            return
        }
        
        p_correctContentOffset()
    }
    
    func p_childScrollViewDidScroll(_ scrollView: UIScrollView) {
        defer {
            if childOffset != scrollView.contentOffset {
                childOffset = scrollView.contentOffset
            }
        }
        p_correctContentOffset()
    }
    
    /// 矫正 contentOffset，
    /// 只有当 chyildScrollView 有效时才会进入该方法。
    func p_correctContentOffset() {
        
        guard let childScrollView = childScrollView else {
            return
        }
        
        let parentOffsetY = parentScrollView.contentOffset.y
        let childOffsetY  = childScrollView.contentOffset.y
        let stickyOffsetY = headerHeight - stickyHeight
        let childTopOffsetY: CGFloat = {
            if #available(iOS 11.0, *) {
                return -childScrollView.adjustedContentInset.top
            } else {
                return -childScrollView.contentInset.top
            }
        }()
        
        if bounces {
            if parentOffsetY < 0.0 {
                childScrollView.contentOffset.y = childTopOffsetY
                return
            }
        }
        
        if parentScrollDirection == .down {
            if childOffsetY > childTopOffsetY {
                parentScrollView.contentOffset.y = stickyOffsetY
            }
        }
        
        if parentScrollView.contentOffset.y > 0.0, parentScrollView.contentOffset.y < stickyOffsetY {
            childScrollView.contentOffset.y = childTopOffsetY
        }
    }
}

// MARK: - Updatable

private extension _FSPagingManager {
    
    // MARK: LayoutUpdate
    
    func p_setNeedsLayoutUpdate() {
        needsLayoutUpdate = true
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }
    
    func p_updateLayoutIfNeeded() {
        if needsLayoutUpdate {
            p_updateLayout()
        }
    }
    
    func p_updateLayout() {
        do {
            p_updatePageScrollableIfNeeded()
            needsLayoutUpdate = false
        }
        do {
            bounces = config.bounces
            if headerHeight > 0.0, stickyHeight >= headerHeight {
                // sticky >= header 时即表示无需 bounces 效果。
                bounces = false
            }
        }
        do {
            let offsetY = parentScrollView.contentOffset.y
            parentScrollView.bounces = bounces
            parentScrollView.contentSize = viewSize
            if config.isSticky {
                parentScrollView.contentSize.height += (headerHeight - stickyHeight)
                parentScrollView.contentOffset.y = offsetY
            } else {
                parentScrollView.contentOffset.y = 0.0
            }
        }
        do {
            let x = contentInset.left
            let y = contentInset.top + headerHeight
            let w = viewSize.width - contentInset.left - contentInset.right
            let h = viewSize.height - contentInset.top - contentInset.bottom - headerHeight + (config.isSticky ? (headerHeight - stickyHeight) : 0.0)
            pageView.frame = .init(x: x, y: y, width: w, height: h)
        }
    }
    
    // MARK: PageScrollableUpdate
    
    func p_setNeedsPageScrollableUpdate() {
        needsPageScrollableUpdate = true
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }
    
    func p_updatePageScrollableIfNeeded() {
        if needsPageScrollableUpdate {
            p_updatePageScrollable()
        }
    }
    
    func p_updatePageScrollable() {
        defer {
            p_setNeedsLayoutUpdate()
        }
        do {
            needsPageScrollableUpdate = false
            config = FSPagingConfig()
            p_clearChildObservation()
        }
        guard let scrollable = p_viewController(at: currentPage) as? FSPagingViewControllerPageScrollable else {
            return
        }
        config = scrollable.pagingConfig(for: pagingViewController)
        if let scrollView = scrollable.scrollView(for: pagingViewController) {
            parentScrollView.simultaneouslyGestureRecognizers.append(scrollView.panGestureRecognizer)
            childOffset = scrollView.contentOffset
            childScrollView = scrollView
            childOffsetObservation = scrollView.observe(\UIScrollView.contentOffset, options: [.old, .new], changeHandler: { [weak self] (view, change) in
                guard
                    let self = self,
                    let newOffset = change.newValue,
                    let oldOffset = change.oldValue
                else {
                    return
                }
                if oldOffset.y != newOffset.y {
                    self.p_scrollViewDidScroll(view)
                }
            })
        }
    }
}

// MARK: - Internal

extension _FSPagingManager {
    
    func setupViews() {
        defer {
            setNeedsReload()
            p_setNeedsLayoutUpdate()
        }
        do {
            if #available(iOS 11.0, *) {
                parentScrollView.contentInsetAdjustmentBehavior = .never
            } else {
                pagingViewController.automaticallyAdjustsScrollViewInsets = false
            }
        }
        do {
            pagingViewController.addChild(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.didMove(toParent: pagingViewController)
        }
    }
    
    func viewDidLayoutSubviews() {
        defer {
            reloadIfNeeded()
            p_updateLayoutIfNeeded()
        }
        if viewSize != view.bounds.size {
            viewSize = view.bounds.size
            needsLayoutUpdate = true
        }
    }
    
    func setNeedsPageScrollableUpdate() {
        p_setNeedsPageScrollableUpdate()
        p_setNeedsLayoutUpdate()
    }
    
    func setNeedsReload() {
        needsReload = true
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }
    
    func reloadIfNeeded() {
        if needsReload {
            reload()
        }
    }
    
    func reload() {
        
        needsReload = false
        
        pageViewController.removeAll()
        
        guard let source = pagingDataSource else {
            p_reset()
            return
        }
        
        numberOfPages = source.numberOfPages(in: pagingViewController)
        numberOfPages = max(0, numberOfPages)
        
        if numberOfPages == 0 {
            return
        }
        
        var index = source.defaultPage(for: pagingViewController)
        if index < 0 || index >= numberOfPages {
            index = 0
        }
        
        currentPage = index
        let viewController = source.pagingViewController(pagingViewController, viewControllerForPageAt: index)
        p_record(viewController, at: index)
        pageViewController.setViewController(viewController, direction: .forward, animated: false)
    }
    
    func removeAll() {
        pageViewController.setViewController(nil, direction: .forward, animated: false)
        p_reset()
    }
    
    func scrollToViewController(at index: Int, animated: Bool) {
        guard
            index >= 0,
            index < numberOfPages,
            index != currentPage,
            let source = pagingDataSource
        else {
            return
        }
        let viewController = source.pagingViewController(pagingViewController, viewControllerForPageAt: index)
        let direction: FSPageViewController.NavigationDirection = index > currentPage ? .forward : .reverse
        pageViewController.setViewController(viewController, direction: direction, animated: animated)
        p_record(viewController, at: index)
    }
}

// MARK: - UIScrollViewDelegate

extension _FSPagingManager: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === parentScrollView {
            p_parentScrollViewDidScroll(scrollView)
        }
        if scrollView === childScrollView {
            p_childScrollViewDidScroll(scrollView)
        }
    }
}

// MARK: - FSPageViewControllerDataSource

extension _FSPagingManager: FSPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: FSPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pagingIndex = caches.object(forKey: viewController) else { return nil }
        var nextIndex = pagingIndex.page - 1
        if nextIndex < 0 {
            if !isInfinite {
                return nil
            }
            nextIndex = numberOfPages - 1 // 循环，跳到最后一页。
        }
        let vc = pagingDataSource?.pagingViewController(pagingViewController, viewControllerForPageAt: nextIndex)
        if let vc = vc {
            p_record(vc, at: nextIndex)
        }
        return vc
    }
    
    func pageViewController(_ pageViewController: FSPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pagingIndex = caches.object(forKey: viewController) else { return nil }
        var nextIndex = pagingIndex.page + 1
        if nextIndex >= numberOfPages {
            if !isInfinite {
                return nil
            }
            nextIndex = 0 // 循环，跳到第一页。
        }
        let vc = pagingDataSource?.pagingViewController(pagingViewController, viewControllerForPageAt: nextIndex)
        if let vc = vc {
            p_record(vc, at: nextIndex)
        }
        return vc
    }
}

// MARK: - FSPageViewControllerDelegate

extension _FSPagingManager: FSPageViewControllerDelegate {
    
    func pageViewControllerWillBeginDragging(_ pageViewController: FSPageViewController) {
        pagingDelegate?.pagingViewControllerWillBeginDragging(pagingViewController)
    }
    
    func pageViewControllerDidEndDragging(_ pageViewController: FSPageViewController) {
        pagingDelegate?.pagingViewControllerDidEndDragging(pagingViewController)
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            willBeginScrollingFrom fromViewController: UIViewController,
                            to toViewController: UIViewController) {
        guard
            let fromIndex = caches.object(forKey: fromViewController)?.page,
            let toIndex = caches.object(forKey: toViewController)?.page
        else {
            assert(false, "There must be something wrong, right?")
            return
        }
        pagingDelegate?.pagingViewController(pagingViewController, willBeginScrollingFrom: fromIndex, to: toIndex)
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            isScrollingFrom fromViewController: UIViewController,
                            to toViewController: UIViewController,
                            progress: CGFloat) {
        guard
            let fromIndex = caches.object(forKey: fromViewController)?.page,
            let toIndex = caches.object(forKey: toViewController)?.page
        else {
            assert(false, "There must be something wrong, right?")
            return
        }
        pagingDelegate?.pagingViewController(pagingViewController, isScrollingFromIndex: fromIndex, toIndex: toIndex, progress: progress)
    }
    
    func pageViewController(_ pageViewController: FSPageViewController, didFinishScrollingTo viewController: UIViewController) {
        defer {
            p_updatePageScrollable()
        }
        guard let pagingIndex = caches.object(forKey: viewController) else {
            assert(false, "There must be something wrong, right?")
            return
        }
        currentPage = pagingIndex.page
        pagingDelegate?.pagingViewController(pagingViewController, didFinishScrollingTo: currentPage)
    }
}

// MARK: - FSPageViewControllerGestureRecognizerDelegate

extension _FSPagingManager: FSPageViewControllerGestureRecognizerDelegate {
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if shouldRecognizeSimultaneously?(gestureRecognizer, otherGestureRecognizer) ?? false {
            return true
        }
        // 首屏
        if currentPage == 0, !isInfinite {
            // `FDFullscreenPopGestureRecognizer` 全屏返回手势。
            if let delegate = otherGestureRecognizer.delegate,
               let cls = NSClassFromString("_FDFullscreenPopGestureRecognizerDelegate"),
               delegate.isKind(of: cls.self)
            {
                return true
            }
            // `FSFullscreenPopGestureRecognizerDelegate` 全屏返回手势。
            if let delegate = otherGestureRecognizer.delegate,
               let cls = NSClassFromString("FSFullscreenPopGestureRecognizerDelegate"),
               delegate.isKind(of: cls.self)
            {
                return true
            }
            // UINavigationController 的 pop 手势。
            if otherGestureRecognizer.state == .began,
               let view = otherGestureRecognizer.view,
               let cls = NSClassFromString("UILayoutContainerView"),
               view.isKind(of: cls.self)
            {
                return true
            }
        }
        return false
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if shouldRequireFailure?(gestureRecognizer, otherGestureRecognizer) ?? false {
            return true
        }
        // UITableViewCell 滑动手势。
        if otherGestureRecognizer is UIPanGestureRecognizer,
           let view = otherGestureRecognizer.view,
           let cls = NSClassFromString("UITableViewWrapperView"),
           view.isKind(of: cls.self)
        {
            return true
        }
        if let window = view.window {
            if gestureRecognizer.location(in: window).x > 44.0 {
                return false
            }
        } else {
            return false
        }
        // `FDFullscreenPopGestureRecognizer` 全屏返回手势。
        if let delegate = otherGestureRecognizer.delegate,
           let cls = NSClassFromString("_FDFullscreenPopGestureRecognizerDelegate"),
           delegate.isKind(of: cls.self)
        {
            return true
        }
        // `FSFullscreenPopGestureRecognizerDelegate` 全屏返回手势。
        if let delegate = otherGestureRecognizer.delegate,
           let cls = NSClassFromString("FSFullscreenPopGestureRecognizerDelegate"),
           delegate.isKind(of: cls.self)
        {
            return true
        }
        // UINavigationController 的 pop 手势。
        if otherGestureRecognizer.state == .began,
           let view = otherGestureRecognizer.view,
           let cls = NSClassFromString("UILayoutContainerView"),
           view.isKind(of: cls.self)
        {
            return true
        }
        return false
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        
        guard isPagingEnabled else {
            return false
        }
        
        if isInfinite {
            return true
        }
        // Fix: PageViewController 嵌套 PageViewController 时无法跨 PageViewController 连续滑动。
        if currentPage == 0 || currentPage == numberOfPages - 1 {
            if let _ = pagingViewController.p_pageViewController {
                if let view = panGestureRecognizer.view {
                    let velocity = panGestureRecognizer.velocity(in: view)
                    if velocity.x > 0.0 {
                        if currentPage == 0 {
                            return false
                        }
                    } else if velocity.x < 0.0 {
                        if currentPage == numberOfPages - 1 {
                            return false
                        }
                    }
                }
            }
        }
        return true
    }
}


// MARK: - _PagingIndex
private class _PagingIndex {
    
    let page: Int
    
    init(page: Int) {
        self.page = page
    }
}

// MARK: - _ScrollDirection
private enum _ScrollDirection {
    /// 内容往上移动
    case up
    /// 内容往下移动
    case down
    /// 不上不下，静止不动
    case stop
}

// MARK: - UIViewController Extension
extension UIViewController {
    
    /// 查找当前 UIViewController 所在的 FSPageViewController（不包含当前 viewController）。
    fileprivate var p_pageViewController: FSPageViewController? {
        guard let parent = self.parent else {
            return nil
        }
        if let parent = parent as? FSPageViewController {
            return parent
        }
        return parent.p_pageViewController
    }
}
