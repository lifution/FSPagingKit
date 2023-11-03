//
//  FSPageTitleView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

/// PageTitleView 的抽象基类，不可直接使用，需继承使用。
open class FSPageTitleView: UIView {
    
    // MARK: Properties/Public
    
    /// 设置该属性相当于调用 `setSelected(isSelected, animated: false)`。
    public var isSelected: Bool {
        get { return p_isSelected }
        set { setSelected(newValue, animated: false) }
    }
    
    /// 抽象的标题对象。
    public let title: FSPageTitle
    
    // MARK: Properties/Private
    
    private var p_isSelected: Bool = false
    
    // MARK: Initialization
    
    public required init(title: FSPageTitle) {
        self.title = title
        super.init(frame: .zero)
        p_didInitialize()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private
    
    private func p_didInitialize() {
        defer {
            didInitialize()
            renderContents()
        }
        backgroundColor = .clear
    }
    
    // MARK: Open
    
    /// 完成初始化后会调用该方法。
    /// 基类默认没有任何实现。
    open func didInitialize() {
        
    }
    
    /// 更新内容。
    ///
    /// - 基类默认没有任何实现。
    /// - 如果要更新 view 的内容，可在该方法中更新。
    /// - 该方法会紧接着 `didInitialize()` 方法之后被调用一次。
    /// - 当 FSPageTitle 调用 `reload(:)` 方法后，与 FSPageTitle 对应的 FSPageTitleView 会自动调用该方法。
    ///
    open func renderContents() {
        
    }
    
    /// PageViewController 滑动过程中的联动变形。
    /// 子类可重载该方法自定义变形。
    ///
    /// - Parameters:
    ///   - progress: 变形进度，范围为 [0, 1]，0 表示未选中状态，1 表示选中状态。
    ///
    open func transform(_ progress: CGFloat) {
        
    }
    
    /// 设置 FSPageTitleView 的选中状态。
    /// 基类默认只记录 selected，如需动画，需要子类自己实现。
    open func setSelected(_ selected: Bool, animated: Bool) {
        p_isSelected = selected
    }
}
