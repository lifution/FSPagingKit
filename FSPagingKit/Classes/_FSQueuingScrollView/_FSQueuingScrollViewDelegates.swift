//
//  _FSQueuingScrollViewDelegates.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

// MARK: -
protocol _FSQueuingScrollViewAppearanceDelegate: AnyObject {
    func viewWillMoveToSuperview(_ view: UIView, newSuperview: UIView?)
    func viewDidMoveToSuperview(_ view: UIView)
    func viewWillAppear(_ view: UIView, animated: Bool)
    func viewDidAppear(_ view: UIView)
    func viewWillDisappear(_ view: UIView, animated: Bool)
    func viewDidDisappear(_ view: UIView)
    // fromView 可能不存在，比如第一个显示的 view，或者是无动画切换 view。
    func visibleViewChange(from fromView: UIView?, to toView: UIView, progress: CGFloat)
}
extension _FSQueuingScrollViewAppearanceDelegate {
    func viewWillMoveToSuperview(_ view: UIView, newSuperview: UIView?) {}
    func viewDidMoveToSuperview(_ view: UIView) {}
    func viewWillAppear(_ view: UIView, animated: Bool) {}
    func viewDidAppear(_ view: UIView) {}
    func viewWillDisappear(_ view: UIView, animated: Bool) {}
    func viewDidDisappear(_ view: UIView) {}
    func visibleViewChange(from fromView: UIView?, to toView: UIView, progress: CGFloat) {}
}


// MARK: -
protocol _FSQueuingScrollViewGestureRecognizerDelegate: AnyObject {
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool
}
extension _FSQueuingScrollViewGestureRecognizerDelegate {
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView,
                           panGestureRecognizerShouldBegin panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return true
    }
}


// MARK: -
protocol _FSQueuingScrollViewScrollDelegate: AnyObject {
    func queuingScrollViewWillBeginDragging(_ queuingScrollView: _FSQueuingScrollView)
    func queuingScrollViewDidEndDragging(_ queuingScrollView: _FSQueuingScrollView)
}
extension _FSQueuingScrollViewScrollDelegate {
    func queuingScrollViewWillBeginDragging(_ queuingScrollView: _FSQueuingScrollView) {}
    func queuingScrollViewDidEndDragging(_ queuingScrollView: _FSQueuingScrollView) {}
}
