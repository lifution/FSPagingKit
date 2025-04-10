//
//  TagViewController.swift
//  FSPagingKit_Example
//
//  Created by VincentLee on 2025/4/10.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit

final class TagViewController: UIViewController {
    private let label = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        label.font = .boldSystemFont(ofSize: 50.0)
        label.text = title
        label.textColor = .black
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
