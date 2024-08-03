//
//  UIViewController+Paging.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

public extension FSPagingKitWrapper where Base: UIViewController {
    
    /// 设置当前控制器所在的 FSPagingViewController 进入更新布局状态。
    ///
    /// - Note:
    ///   - 该方法为 FSPagingViewController 类特供，
    ///     仅当当前控制器是在 FSPagingViewController 容器下时该方法才有效（当前控制器就是 FSPagingViewController 时同样有效）。
    ///   - 当当前控制器一些与 FSPagingViewController 相关的参数更新后可调用该方法让 FSPagingViewController 进入更新操作。
    ///
    func setNeedsPageScrollableUpdate() {
        if let pagingVC = base.pagingViewController {
            pagingVC.setNeedsPageScrollableUpdate()
        }
    }
}

private extension UIResponder {
    
    var pagingViewController: FSPagingViewController? {
        if let vc = self as? FSPagingViewController {
            return vc
        }
        guard let next = self.next else {
            return nil
        }
        if let vc = next as? FSPagingViewController {
            return vc
        }
        return next.pagingViewController
    }
}
