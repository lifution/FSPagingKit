//
//  FSPagingViewControllerDelegate.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

public protocol FSPagingViewControllerDelegate: AnyObject {
    
    func pagingViewControllerWillBeginDragging(_ pagingViewController: FSPagingViewController)
    
    func pagingViewControllerDidEndDragging(_ pagingViewController: FSPagingViewController)
    
    func pagingViewController(_ pagingViewController: FSPagingViewController,
                              willBeginScrollingFrom fromIndex: Int,
                              to toIndex: Int)
    
    func pagingViewController(_ pagingViewController: FSPagingViewController,
                            isScrollingFromIndex fromIndex: Int,
                            toIndex: Int,
                            progress: CGFloat)
    
    func pagingViewController(_ pagingViewController: FSPagingViewController, didFinishScrollingTo index: Int)
}

public extension FSPagingViewControllerDelegate {
    func pagingViewControllerWillBeginDragging(_ pagingViewController: FSPagingViewController) {}
    func pagingViewControllerDidEndDragging(_ pagingViewController: FSPagingViewController) {}
    func pagingViewController(_ pagingViewController: FSPagingViewController,
                              willBeginScrollingFrom fromIndex: Int,
                              to toIndex: Int) {}
    func pagingViewController(_ pagingViewController: FSPagingViewController,
                            isScrollingFromIndex fromIndex: Int,
                            toIndex: Int,
                            progress: CGFloat) {}
    func pagingViewController(_ pagingViewController: FSPagingViewController, didFinishScrollingTo index: Int) {}
}
