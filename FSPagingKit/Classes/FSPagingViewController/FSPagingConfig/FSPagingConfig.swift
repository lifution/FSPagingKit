//
//  FSPagingConfig.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

/// 分页配置，用于配置 FSPagingViewController 每一个页面的状态。
public struct FSPagingConfig {
    
    /// 作为容器的 scrollView 是否支持边缘果冻弹性效果，默认为 false。
    ///
    /// - Note:
    ///   - 当 isSticky 为 true 时，底部会被锁定，即底部无 bounces 效果，只保留顶部 bounces 效果。
    ///
    public var bounces = false
    
    /// 是否悬浮，默认为 false。
    ///
    /// 该属性用于控制当前页的 UIViewController 在 FSPagingViewController 下的悬浮状态。
    /// 如果该属性为 true 即表示当前 UIViewController 需要悬浮（如果 FSPagingViewController 没有 header 和 sticky 距离即表示悬浮在最顶部。）
    /// 如果该属性为 false 则表示当前 UIViewController.height = FSPagingViewController.height - header - footer + sticky。
    ///
    public var isSticky = false
    
    public init() {}
}
