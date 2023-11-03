//
//  FSPageViewControllerDelegate.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

public protocol FSPageViewControllerDelegate: AnyObject {
    
    func pageViewControllerWillBeginDragging(_ pageViewController: FSPageViewController)
    
    func pageViewControllerDidEndDragging(_ pageViewController: FSPageViewController)
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            willBeginScrollingFrom fromViewController: UIViewController,
                            to toViewController: UIViewController)
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            isScrollingFrom fromViewController: UIViewController,
                            to toViewController: UIViewController,
                            progress: CGFloat)
    
    func pageViewController(_ pageViewController: FSPageViewController, didFinishScrollingTo viewController: UIViewController)
}

public extension FSPageViewControllerDelegate {
    func pageViewControllerWillBeginDragging(_ pageViewController: FSPageViewController) {}
    func pageViewControllerDidEndDragging(_ pageViewController: FSPageViewController) {}
    func pageViewController(_ pageViewController: FSPageViewController,
                            isScrollingFrom fromViewController: UIViewController,
                            to toViewController: UIViewController,
                            progress: CGFloat) {}
    func pageViewController(_ pageViewController: FSPageViewController, didFinishScrollingTo viewController: UIViewController) {}
}
