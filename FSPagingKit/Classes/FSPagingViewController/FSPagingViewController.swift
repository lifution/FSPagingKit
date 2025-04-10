//
//  FSPagingViewController.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

/// FSPagingViewController 内部管理着一个 FSPageViewController，
/// 该类做了一些常规的封装，API 相对于 FSPageViewController 更友好，
/// 使用起来也更方便，日常开发中推荐使用该类，如需要做更复杂的封装才
/// 推荐使用 FSPageViewController。
open class FSPagingViewController: UIViewController {
    
    // MARK: Properties/Public
    ///
    /// 此处读取的 delegate 是设定的多个 delegate 中的第一个
    /// 设置该属性会覆盖所有的其它 delegate，效果相当于 ``set(delegate:)``，
    /// 如果需要添加多 delegate，则需要调用 ``add(delegate:)`` 方法。
    /// 
    public final weak var delegate: FSPagingViewControllerDelegate? {
        get { return manager.pagingDelegate }
        set { manager.set(delegate: newValue) }
    }
    ///
    /// 数据源
    ///
    public final weak var dataSource: FSPagingViewControllerDataSource? {
        get { return manager.pagingDataSource }
        set { manager.pagingDataSource = newValue }
    }
    ///
    /// 头部高度。
    /// 可在该区域放置 titlesView 等控件。
    ///
    public final var headerHeight: CGFloat {
        get { return manager.headerHeight }
        set { manager.headerHeight = newValue }
    }
    ///
    /// 悬浮高度。
    /// 该数值表示的是从当前页面顶部到悬浮位置的距离 (横向滚动内容顶部到悬浮位置的距离)。
    /// child view controller 需要遵循 FSPagingViewControllerPageScrollable 协议才能实现悬浮等效果。
    ///
    public final var stickyHeight: CGFloat {
        get { return manager.stickyHeight }
        set { manager.stickyHeight = newValue }
    }
    ///
    /// 内容偏移
    /// page 内容是铺满整个 view controller，但有时候会有需求把 page 偏移一部分，比如
    /// navigation bar 或 tab bar。
    /// 用法类似 UIScrollView 的 contentInset。
    /// 默认为 .zero
    ///
    public final var contentInset: UIEdgeInsets {
        get { return manager.contentInset }
        set { manager.contentInset = newValue }
    }
    ///
    /// 是否为循环滑动，默认为 false。
    ///
    public final var isInfinite: Bool {
        get { return manager.isInfinite }
        set { manager.isInfinite = newValue }
    }
    ///
    /// 是否允许滑动翻页，默认为 true。
    ///
    public final var isPagingEnabled: Bool {
        get { return manager.isPagingEnabled }
        set { manager.isPagingEnabled = newValue }
    }
    ///
    /// 是否由子控制器来控制状态栏，比如状态栏的 hidden 或者 style。
    ///
    public final var shouldControlStatusBarByChild = true {
        didSet {
            if shouldControlStatusBarByChild != oldValue {
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    ///
    /// 与 FSPageViewController 横向滑动手势同步进行的手势集合。
    /// 如果外部有需要与 page 横向 scrollView 同步进行手势可添加到该集合中。
    ///
    public final var simultaneouslyGestureRecognizers = [UIGestureRecognizer]()
    ///
    /// 容器滚动回调，即最底层的 UIScrollView 滚动回调。
    /// 可实现该 closure 监听容器 scrollView 的滚动，以实现一些效果，比如头部放大、头部渐变等效果。
    ///
    public final var onContainerDidScroll: ((CGPoint) -> Void)?
    
    // MARK: Properties/Private
    
    private let manager = _FSPagingManager()
    
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
        manager.pagingViewController = self
        manager.onParentDidScroll = { [weak self] offset in
            self?.onContainerDidScroll?(offset)
        }
        manager.shouldRecognizeSimultaneously = { [weak self] (gestureRecognizer, otherGestureRecognizer) in
            guard let self = self else { return false }
            return self.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
        }
        manager.shouldRequireFailure = { [weak self] (gestureRecognizer, otherGestureRecognizer) in
            guard let self = self else { return false }
            return self.gestureRecognizer(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer)
        }
    }
    
    // MARK: Open
    
    open func scrollToViewController(at index: Int, animated: Bool) {
        manager.scrollToViewController(at: index, animated: animated)
    }
    
    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if simultaneouslyGestureRecognizers.contains(otherGestureRecognizer) {
            return true
        }
        return false
    }
    
    open func gestureRecognizer(
        _ pageViewController: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}

// MARK: - Life Cycle

extension FSPagingViewController {
    
    public final override func loadView() {
        view = manager.parentScrollView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        manager.setupViews()
    }
}

// MARK: - Override

extension FSPagingViewController {
    
    open override var childForStatusBarStyle: UIViewController? {
        if shouldControlStatusBarByChild {
            return manager.pageViewController
        }
        return nil
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        if shouldControlStatusBarByChild {
            return manager.pageViewController
        }
        return nil
    }
    
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return manager.pageViewController
    }
    
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        return manager.pageViewController
    }
    
    open override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        manager.viewDidLayoutSubviews()
    }
}

// MARK: - Public

public extension FSPagingViewController {
    
    func setNeedsReload() {
        manager.setNeedsReload()
    }
    
    func reloadIfNeeded() {
        manager.reloadIfNeeded()
    }
    
    func reload() {
        manager.reload()
    }
    
    func removeAll() {
        manager.removeAll()
    }
    
    func setNeedsPageScrollableUpdate() {
        manager.setNeedsPageScrollableUpdate()
    }
    
    func set(delegate: (any FSPagingViewControllerDelegate)?) {
        manager.set(delegate: delegate)
    }
    
    func add(delegate: (any FSPagingViewControllerDelegate)?) {
        manager.add(delegate: delegate)
    }
    
    func remove(delegate: (any FSPagingViewControllerDelegate)?) {
        manager.remove(delegate: delegate)
    }
}
