//
//  FSPageViewControllerGestureRecognizerDelegate.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

public protocol FSPageViewControllerGestureRecognizerDelegate: AnyObject {
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
    
    /// 是否允许 _FSQueuingScrollView 的 panGestureRecognizer 启动。
    func pageViewController(_ pageViewController: FSPageViewController,
                            panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool
}

public extension FSPageViewControllerGestureRecognizerDelegate {
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            gestureRecognizer: UIGestureRecognizer,
                            shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func pageViewController(_ pageViewController: FSPageViewController,
                            panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return true
    }
}
