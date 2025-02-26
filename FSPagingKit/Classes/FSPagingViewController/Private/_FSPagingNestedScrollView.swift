//
//  _FSPagingNestedScrollView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit
import Combine

final class _FSPagingNestedScrollView: UIScrollView {
    
    var simultaneouslyGestureRecognizers = [UIGestureRecognizer]()
    let backgroundColorPublisher = PassthroughSubject<UIColor?, Never>()
    
    override var backgroundColor: UIColor? {
        didSet {
            backgroundColorPublisher.send(backgroundColor)
        }
    }
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        p_didInitialize()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private

private extension _FSPagingNestedScrollView {
    
    /// Invoked after initialization.
    func p_didInitialize() {
        bounces = false
        scrollsToTop = false
        clipsToBounds = true
        backgroundColor = .white
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
    }
}

// MARK: - UIGestureRecognizerDelegate

extension _FSPagingNestedScrollView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if simultaneouslyGestureRecognizers.contains(otherGestureRecognizer) {
            return true
        }
        return false
    }
}
