//
//  FSPageScaleTextTitleView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

final class FSPageScaleTextTitleView: FSPageTitleView {
    
    // MARK: Properties/Private
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.layer.anchorPoint = .init(x: 0.5, y: 1.0)
        return label
    }()
    
    private var viewSize: CGSize = .zero
    private var needsResetLabelFrame = false
    
    // MARK: Override
    
    override func didInitialize() {
        addSubview(textLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if viewSize != bounds.size {
            viewSize = bounds.size
            needsResetLabelFrame = true
        }
        if needsResetLabelFrame {
            
            needsResetLabelFrame = false
            
            let size: CGSize = {
                if let title = title as? FSPageTextTitle, let text = title.normalContent as? NSAttributedString {
                    let size = text.boundingRect(with: .init(width: 10000.0, height: 10000.0), options: [], context: nil)
                    return .init(width: ceil(size.width), height: ceil(size.height))
                }
                return .zero
            }()
            let x = ceil((viewSize.width - size.width) / 2.0)
            let y = ceil((viewSize.height - size.height) / 2.0)
            
            let transform = textLabel.transform
            textLabel.transform = .identity
            textLabel.frame = .init(origin: .init(x: x, y: y), size: size)
            textLabel.transform = transform
        }
    }
    
    override func renderContents() {
        setSelected(isSelected, animated: false)
        needsResetLabelFrame = true
        setNeedsLayout()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        transform(isSelected ? 1.0 : 0.0)
    }
    
    override func transform(_ progress: CGFloat) {
        guard let title = title as? FSPageTextTitle else {
            return
        }
        textLabel.attributedText = title.attributedText(progress)
        do {
            let minScale: CGFloat = 0.7
            if progress <= 0.0 {
                textLabel.transform = .init(scaleX: minScale, y: minScale)
            } else if progress >= 1.0 {
                textLabel.transform = .identity
            } else {
                let scale_progress = minScale + (1.0 - minScale) * progress
                textLabel.transform = .init(scaleX: scale_progress, y: scale_progress)
            }
        }
    }
}
