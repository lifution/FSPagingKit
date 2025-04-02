//
//  FSPageTitlesView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

/// 分页标题控件。
///
/// - Note:
///   - 每一个 FSPageTitle 表示一个 `标题`。
///   - 每一个 FSPageTitle 都对应一个 FSPageTitleView，而且 FSPageTitleView 不会复用。
///
open class FSPageTitlesView: UIScrollView {
    
    /// 标题布局类型
    public enum LayoutType {
        /// 外部手动配置宽度
        case manually
        /// 根据布局空间等宽布局
        case equally
    }
    
    // MARK: Properties/Public
    
    /// 标题对象集合。
    ///
    /// - Note:
    ///   * 每次修改该属性后，都会刷新整个 TitlesView。
    ///
    public var titles: [FSPageTitle]? {
        didSet {
            p_setNeedsReload()
        }
    }
    
    /// 选中 titile 的下标，如果没有选中的 title，则返回 nil。
    ///
    /// - Note:
    ///   * 在 titles 更新后，如果 indexForSelectedTitle 还有效则自动设置对应的选中状态，
    ///     否则把 indexForSelectedTitle 重置为 nil。
    ///
    public private(set) var indexForSelectedTitle: Int?
    
    /// 标题布局类型，默认为 equally。
    ///
    /// * manually: 按照 title 的 width 属性布局。
    /// * equally: 忽略 title 的 width 属性，按照 titles 的数量和当前 titlesView 的宽度等宽布局。
    ///
    public var layoutType: FSPageTitlesView.LayoutType = .equally {
        didSet {
            if layoutType != oldValue {
                p_setNeedsReload()
            }
        }
    }
    
    /// 点击选中处理器。
    ///
    /// - 外部可通过该 closure 控制 PageTitleView 是否被选中。
    /// - 允许点击选中 title 则在该 closure 中返回 true，否则返回 false。
    ///
    public var selectionHandler: ((_ index: Int) -> Bool)?
    
    /// 是否隐藏指示器，默认为 false。
    public var isIndicatorHidden = false {
        didSet {
            p_updateIndicator()
        }
    }
    
    /// indicator。
    ///
    /// - Note:
    ///   - 该容器的大小和 title 的大小一致。
    ///   - 外部可将自定义的 indicator 添加到该容器上。
    ///   - 默认的指示器样式为 `bar`。
    ///
    public let indicatorView = FSPageTitlesIndicatorView()
    
    // MARK: Properties/Private
    
    private var viewSize = CGSize.zero
    
    private var needsReload = false
    
    private var titleViews = [FSPageTitleView]()
    
    private var selectedTitleView: FSPageTitleView?
    
    // MARK: Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        p_didInitialize()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Override

extension FSPageTitlesView {
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard
            let titleView = p_titleView(for: touches),
            titleView !== selectedTitleView,
            let index = titleViews.firstIndex(of: titleView)
        else {
            return
        }
        if let handler = selectionHandler {
            let shouldSelect = handler(index)
            if shouldSelect {
                selectTitle(at: index, animated: true)
            }
        } else {
            selectTitle(at: index, animated: true)
        }
    }
    
    open override func layoutSubviews() {
        defer {
            p_reloadIfNeeded()
        }
        super.layoutSubviews()
        if viewSize != bounds.size {
            viewSize = bounds.size
            contentSize.height = viewSize.height
            indicatorView.frame.origin.y = 0.0
            indicatorView.frame.size.height = bounds.height
            p_updateTitlesLayout()
        }
    }
}

// MARK: - Private

private extension FSPageTitlesView {
    
    /// Invoked after initialization.
    func p_didInitialize() {
        defer {
            p_setNeedsReload()
        }
        do {
            scrollsToTop = false
            backgroundColor = .clear
            showsVerticalScrollIndicator = false
            showsHorizontalScrollIndicator = false
            if #available(iOS 11.0, *) {
                contentInsetAdjustmentBehavior = .never
            }
        }
        do {
            addSubview(indicatorView)
        }
    }
    
    func p_setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }
    
    func p_reloadIfNeeded() {
        if needsReload {
            p_reload()
        }
    }
    
    func p_reload() {
        
        defer {
            if let index = indexForSelectedTitle {
                if index < titleViews.count {
                    selectedTitleView = titleViews[index]
                    selectedTitleView?.setSelected(true, animated: false)
                } else {
                    indexForSelectedTitle = nil
                }
            }
            p_updateTitlesLayout()
            if let index = indexForSelectedTitle {
                p_centerTitleView(at: index, animated: false)
            }
        }
        
        needsReload = false
        selectedTitleView = nil
        
        titleViews.forEach { $0.removeFromSuperview() }
        titleViews = titles?.compactMap {
            let view = $0.classType.init(title: $0)
            addSubview(view)
            do {
                $0.reloadHandler = { [weak view, weak self] (title, type) in
                    view?.renderContents()
                    if type == .reload {
                        self?.p_updateTitlesLayout()
                    }
                }
            }
            return view
        } ?? []
    }
    
    func p_updateTitlesLayout() {
        
        defer {
            bounces = contentSize.width > viewSize.width
            p_updateIndicator()
        }
        
        guard !titleViews.isEmpty else {
            contentSize.width = 0.0
            return
        }
        
        let widths: [CGFloat] = {
            switch layoutType {
            case .manually:
                return titleViews.compactMap { $0.title.width }
            case .equally:
                var margins: CGFloat = 0.0
                titleViews.forEach { margins += ($0.title.margin.left + $0.title.margin.right) }
                let width = floor((viewSize.width - margins) / CGFloat(titleViews.count))
                return titleViews.compactMap { _ in width }
            }
        }()
        
        var lastTitleView: FSPageTitleView?
        for (index, view) in titleViews.enumerated() {
            view.frame.origin.x = {
                var x: CGFloat = 0.0
                if let last = lastTitleView {
                    x = last.frame.maxX + last.title.margin.right
                }
                x += view.title.margin.left
                return x
            }()
            view.frame.size.width = widths[index]
            view.frame.size.height = bounds.height
            lastTitleView = view
        }
        contentSize.width = lastTitleView!.frame.maxX + lastTitleView!.title.margin.right
    }
    
    func p_updateIndicator() {
        guard
            !titleViews.isEmpty,
            let index = indexForSelectedTitle,
            let frame = p_frameForTitleView(at: index)
        else {
            indicatorView.isHidden = true
            return
        }
        indicatorView.isHidden = isIndicatorHidden
        indicatorView.frame.origin.x = frame.minX
        indicatorView.frame.size.width = frame.width
    }
    
    func p_frameForTitleView(at index: Int) -> CGRect? {
        guard !needsReload, index >= 0, index < titleViews.count else {
            return nil
        }
        return titleViews[index].frame
    }
    
    func p_titleView(for touches: Set<UITouch>) -> FSPageTitleView? {
        guard let touch = touches.first else { return nil }
        let point = touch.location(in: self)
        for view in titleViews {
            if view.frame.contains(point) {
                return view
            }
        }
        return nil
    }
    
    func p_centerTitleView(at index: Int, animated: Bool) {
        let scrollableWidth = contentSize.width + contentInset.left + contentInset.right
        guard
            scrollableWidth > bounds.width,
            let frame = p_frameForTitleView(at: index)
        else {
            return
        }
        let isFrameVisible: Bool = {
            let intersection = bounds.intersection(frame)
            if intersection.width < frame.width {
                return false
            }
            if intersection == frame {
                let left = frame.minX - bounds.minX
                if left < 50.0 {
                    return false
                }
                let right = bounds.maxX - frame.maxX
                if right < 50.0 {
                    return false
                }
            }
            return true
        }()
        if isFrameVisible {
            return
        }
        var offsetX = frame.midX - viewSize.width / 2.0
        if offsetX < 0.0 {
            offsetX = -contentInset.left
        }
        if offsetX > (contentSize.width - viewSize.width) {
            offsetX = contentSize.width - viewSize.width + contentInset.right
        }
        if offsetX == contentOffset.x {
            return
        }
        let offset = CGPoint(x: offsetX, y: contentOffset.y)
        setContentOffset(offset, animated: animated)
    }
}

// MARK: - FSPagingViewControllerDelegate

extension FSPageTitlesView: FSPagingViewControllerDelegate {
    
    public func pagingViewControllerWillBeginDragging(_ pagingViewController: FSPagingViewController) {
        isUserInteractionEnabled = false
    }
    
    public func pagingViewControllerDidEndDragging(_ pagingViewController: FSPagingViewController) {
        isUserInteractionEnabled = true
    }
    
    public func pagingViewController(_ pagingViewController: FSPagingViewController,
                                     willBeginScrollingFrom fromIndex: Int,
                                     to toIndex: Int) {
        p_centerTitleView(at: toIndex, animated: true)
    }
    
    public func pagingViewController(_ pagingViewController: FSPagingViewController,
                                     isScrollingFromIndex fromIndex: Int,
                                     toIndex: Int,
                                     progress: CGFloat) {
        guard
            fromIndex >= 0,
            fromIndex < titleViews.count,
            toIndex >= 0,
            toIndex < titleViews.count,
            let fromFrame = p_frameForTitleView(at: fromIndex),
            let toFrame   = p_frameForTitleView(at: toIndex)
        else {
            return
        }
        if fromIndex == toIndex {
            indicatorView.frame.origin.x = fromFrame.minX
        } else {
            
            indicatorView.frame.origin.x = fromFrame.minX + (toFrame.minX - fromFrame.minX) * progress
            indicatorView.frame.size.width = fromFrame.width + (toFrame.width - fromFrame.width) * progress
            
            let fromView = titleViews[fromIndex]
            let toView = titleViews[toIndex]
            fromView.transform(1.0 - progress)
            toView.transform(progress)
        }
    }
    
    public func pagingViewController(_ pagingViewController: FSPagingViewController, didFinishScrollingTo index: Int) {
        selectTitle(at: index, animated: false)
    }
}

// MARK: - Public

public extension FSPageTitlesView {
    
    /// 标记需要刷新 titles 列表。
    ///
    /// - 需要在 main thread 中调用该方法。
    /// - 调用该方法不会立马执行 reload 操作，刷新操作会在下一个 update cycle 中执行。
    /// - 在下一个 update cycle 到来之前，多次调用该方法与调用一次都是同样的。
    ///
    func setNeedsReload() {
        p_setNeedsReload()
    }
    
    /// 如果已调用 `setNeedsReload()` 方法标记了更新，再调用该方法会立马执行 reload 操作。
    ///
    /// - 如果未调用 `setNeedsReload()` 标记，调用该方法是无效的。
    ///
    func reloadIfNeeded() {
        p_reloadIfNeeded()
    }
    
    /// 刷新 titles 列表。
    ///
    /// - 该操作会根据最新的 titles 刷新整个 titles 列表，类似 UITableView 的 reloadData。
    /// - 如果只是需要更新单个 title，建议使用 title 的 reload 方法。
    /// - 该操作不会重置 indexForSelectedTitle。
    ///
    func reload() {
        p_reload()
    }
    
    /// 选中指定 index 的 title。
    ///
    /// - Note:
    ///   * 如果 titles 未设置，则调用该方法无效。
    ///   * 如果 index 超出 titles 的范围，调用该方法同样无效。
    ///
    func selectTitle(at index: Int, animated: Bool = false) {
        guard
            let titles = titles,
            !titles.isEmpty,
            index >= 0,
            index < titles.count
        else {
            return
        }
        
        var animated = animated
        
        if indexForSelectedTitle == nil {
            // 从「未选中」变成「选中」，不需要动画
            animated = false
        }
        
        indexForSelectedTitle = index
        
        // 已然设置 titles，但还未布局 TitleViews，
        // 记录 index，待布局 TitleViews 后再做出相应的选中操作。
        if needsReload {
            return
        }
        
        do {
            selectedTitleView?.setSelected(false, animated: animated)
            selectedTitleView = nil
            if index < titleViews.count {
                selectedTitleView = titleViews[index]
                selectedTitleView?.setSelected(true, animated: animated)
            }
        }
        do {
            p_centerTitleView(at: index, animated: animated)
            do {
                if !animated {
                    p_updateIndicator()
                } else {
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut) {
                        self.p_updateIndicator()
                    }
                }
            }
        }
    }
    
    /// 设置纯文本标题，FSPageTitlesView 内部会自动转化为 titles。
    func setTitles(with texts: [String]?) {
        titles = texts?.compactMap { FSPageTextTitle(text: $0) } ?? []
    }
    
    /// 重置选中状态，即全部 title 都恢复为未选中状态
    ///
    func resetSelectionState() {
        indexForSelectedTitle = nil
        p_reload()
    }
}
