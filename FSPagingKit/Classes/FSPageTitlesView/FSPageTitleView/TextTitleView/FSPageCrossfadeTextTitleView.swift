//
//  FSPageCrossfadeTextTitleView.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit

final class FSPageCrossfadeTextTitleView: FSPageTitleView {
    
    // MARK: Properties/Private
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .clear
        return label
    }()
    
    // MARK: Override
    
    override func didInitialize() {
        addSubview(textLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = .init(origin: .zero, size: bounds.size)
    }
    
    override func renderContents() {
        setSelected(isSelected, animated: false)
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
    }
}
