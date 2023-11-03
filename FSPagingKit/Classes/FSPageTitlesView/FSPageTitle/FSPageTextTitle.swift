//
//  FSPageTextTitle.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

public final class FSPageTextTitle: FSPageTitle {
    
    // text transform type
    public enum Transform {
        /// 字体不变，字体颜色渐变过渡。
        case crossfade
        /// 字体大小和颜色同时渐变过渡。
        case scale
    }
    
    // MARK: Properties/Override
    
    public override var classType: FSPageTitleView.Type {
        switch transform {
        case .crossfade:
            return FSPageCrossfadeTextTitleView.self
        case .scale:
            return FSPageScaleTextTitleView.self
        }
    }
    
    // MARK: Properties/Public
    
    public let transform: FSPageTextTitle.Transform
    
    public var font: UIFont {
        didSet {
            p_update()
        }
    }
    
    public var normalColor: UIColor {
        didSet {
            p_update()
        }
    }
    
    public var selectedColor: UIColor {
        didSet {
            p_update()
        }
    }
    
    public var text: String? {
        didSet {
            if text != oldValue {
                p_update()
            }
        }
    }
    
    // MARK: Initialization
    
    public init(text: String? = nil, transform: FSPageTextTitle.Transform = .crossfade) {
        
        self.transform = transform
        
        normalColor = .black
        selectedColor = .blue
        
        switch transform {
        case .crossfade:
            font = .boldSystemFont(ofSize: 16.0)
        case .scale:
            font = .boldSystemFont(ofSize: 24.0)
        }
        
        super.init()
        
        ({ self.text = text })()
    }
    
    // MARK: Private
    
    private func p_update() {
        
        guard let text = self.text else {
            width = 0.0
            normalContent = nil
            selectedContent = nil
            reload(.reload)
            return
        }
        
        let normal_text = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: normalColor
        ])
        let selected_text = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: selectedColor
        ])
        
        normalContent = normal_text
        selectedContent = selected_text
        
        let textWidth = ceil(normal_text.boundingRect(with: .init(width: 10000.0, height: 10000.0), options: [], context: nil).width)
        if width != textWidth {
            width = textWidth
            reload(.reload)
        } else {
            reload(.rerender)
        }
    }
}

// MARK: - Internal

extension FSPageTextTitle {
    
    func attributedText(_ progress: CGFloat) -> NSAttributedString? {
        guard let text = text else {
            return nil
        }
        let textColor: UIColor = {
            switch progress {
            case 0: return normalColor
            case 1: return selectedColor
            default:
                var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
                var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
                guard normalColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else {
                    return normalColor
                }
                guard selectedColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
                    return selectedColor
                }
                return UIColor(red: CGFloat(r1 + (r2 - r1) * progress),
                               green: CGFloat(g1 + (g2 - g1) * progress),
                               blue: CGFloat(b1 + (b2 - b1) * progress),
                               alpha: CGFloat(a1 + (a2 - a1) * progress))
            }
        }()
        
        if progress <= 0.001 {
            return normalContent as? NSAttributedString
        } else if progress >= 1.0 {
            return selectedContent as? NSAttributedString
        } else {
            return NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: textColor
            ])
        }
    }
}
