//
//  FSPagingViewControllerDataSource.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

public protocol FSPagingViewControllerDataSource: AnyObject {
    
    func defaultPage(for pagingViewController: FSPagingViewController) -> Int
    
    func numberOfPages(in pagingViewController: FSPagingViewController) -> Int
    
    func pagingViewController(_ pagingViewController: FSPagingViewController, viewControllerForPageAt index: Int) -> UIViewController
}

public extension FSPagingViewControllerDataSource {
    
    func defaultPage(for pagingViewController: FSPagingViewController) -> Int {
        return 0
    }
}
