//
//  FSPageTitle.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

/// PageTitle 的抽象基类，不可直接使用，需继承使用。
open class FSPageTitle {
    
    /// 刷新类型
    public enum ReloadType {
        /// 只重新绘制，不更新宽度。
        case rerender
        /// 重新绘制，并更新宽度。
        case reload
    }
    
    /// 左右间距。
    public struct Margin: Equatable {
        
        // MARK: Properties/Public
        
        public var left: CGFloat = 0.0
        public var right: CGFloat = 0.0
        
        public static let zero: Margin = .init()
        
        // MARK: Initialization
        
        public init(left: CGFloat = 0.0, right: CGFloat = 0.0) {
            self.left = left
            self.right = right
        }
        
        // MARK: Equatable
        
        public static func == (lhs: Margin, rhs: Margin) -> Bool {
            return lhs.left == rhs.left && lhs.right == rhs.right
        }
    }
    
    // MARK: Properties/Open
    
    /// 标题所占的宽度。
    /// 标题控件的高度默认和 FSPageTitlesView 一致。
    open var width: CGFloat = 0.0
    
    /// 左右的间距。
    open var margin: FSPageTitle.Margin = .zero
    
    /// TitleView 的类型。
    open var classType: FSPageTitleView.Type {
        return FSPageTitleView.self
    }
    
    /// 正常状态下的标题内容。
    open var normalContent: Any?
    
    /// 选中状态下的标题内容。
    open var selectedContent: Any?
    
    // MARK: Properties/Internal
    
    /// reload 处理者，用于 FSPageTitlesView 内部监听当前类的 reload 操作。
    ///
    /// - Warning:
    ///   - ⚠️ FSPageTitlesView 会实现该 closure，其它地方禁止实现。
    ///
    final var reloadHandler: ((FSPageTitle, FSPageTitle.ReloadType) -> Void)?
    
    // MARK: Initialization
    
    public init() {}
    
    // MARK: Public
    
    /// 刷新 title。
    ///
    /// - Parameter type: 刷新类型，默认为 `.reload`。
    ///
    public final func reload(_ type: FSPageTitle.ReloadType = .reload) {
        reloadHandler?(self, type)
    }
}
