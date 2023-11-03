//
//  FSPageTitlesIndicatorView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

/// 用于 FSPageTitlesView 的指示器控件。
public final class FSPageTitlesIndicatorView: UIView {
    
    // MARK: 指示器样式。
    public enum Style {
        case bar
        case custom
    }
    
    // MARK: Properties/Public
    
    public var style: FSPageTitlesIndicatorView.Style = .bar {
        didSet {
            if style != oldValue {
                p_updateStyle()
            }
        }
    }
    
    /// 当 style 为 bar 时的指示器颜色。
    public var barColor: UIColor? = .init(red:0.13, green:0.44, blue:0.88, alpha:1.00) {
        didSet {
            bar?.backgroundColor = barColor
        }
    }
    
    // MARK: Properties/Private
    
    private var bar: UIView?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        p_didInitialize()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Override

extension FSPageTitlesIndicatorView {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let bar = bar {
            let x = (bounds.width - Consts.barSize.width) / 2.0
            let y = bounds.height - Consts.barSize.height
            bar.frame = .init(origin: .init(x: x, y: y), size: Consts.barSize)
        }
    }
}

// MARK: - Private

private extension FSPageTitlesIndicatorView {
    
    /// Invoked after initialization.
    func p_didInitialize() {
        p_updateStyle()
    }
    
    func p_updateStyle() {
        
        if style == .custom {
            bar?.removeFromSuperview()
            bar = nil
        }
        
        if style == .bar {
            if bar == nil {
                let bar = UIView()
                bar.backgroundColor = barColor
                bar.layer.cornerRadius = Consts.barSize.height / 2.0
                addSubview(bar)
                self.bar = bar
            }
            setNeedsLayout()
        }
    }
}

// MARK: - Consts
private struct Consts {
    static let barSize = CGSize(width: 28.0, height: 2.0)
}
