//
//  FSPagingViewControllerPageScrollable.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

public protocol FSPagingViewControllerPageScrollable {
    
    func scrollView(for pagingViewController: FSPagingViewController) -> UIScrollView?
    
    ///
    /// - Note:
    ///   - 如果当前页的 `PagingConfig` 更新了，需调用 `FSPagingViewController.fspk.setNeedsPageScrollableUpdate()`。
    ///
    func pagingConfig(for pagingViewController: FSPagingViewController) -> FSPagingConfig
}

public extension FSPagingViewControllerPageScrollable {
    
    func pagingConfig(for pagingViewController: FSPagingViewController) -> FSPagingConfig {
        return FSPagingConfig()
    }
}
