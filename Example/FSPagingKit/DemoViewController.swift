//
//  DemoViewController.swift
//  FSPagingKit_Example
//
//  Created by VincentLee on 2025/4/10.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import FSPagingKit

final class DemoViewController: FSPagingViewController {
    
    private let titlesView = FSPageTitlesView()
    
    private var childs = [TagViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defer {
            dataSource = self
            add(delegate: titlesView)
        }
        
        let numbers = Array(0..<10)
        childs = numbers.map {
            let vc = TagViewController()
            vc.title = "\($0)"
            return vc
        }
        
        view.backgroundColor = .white
//        view.semanticContentAttribute = .forceLeftToRight
        
        view.addSubview(titlesView)
        titlesView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(0.0)
            make.width.equalToSuperview()
            make.height.equalTo(44.0)
        }
        titlesView.backgroundColor = .cyan.withAlphaComponent(0.15)
        titlesView.titles = numbers.map { "Title-\($0)" }.map {
            let title = FSPageTextTitle(text: $0, transform: .scale)
            title.font = .systemFont(ofSize: 15.0, weight: .medium)
            title.margin.left = 12.0
            return title
        }
        titlesView.titles?.last?.margin.right = 12.0
        titlesView.layoutType = .manually
        titlesView.selectionHandler = { [weak self] index in
            guard let self = self else { return false }
            self.scrollToViewController(at: index, animated: true)
            return false
        }
        titlesView.selectTitle(at: 0, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerHeight = titlesView.frame.maxY
    }
}

extension DemoViewController: FSPagingViewControllerDataSource {
    
    func defaultPage(for pagingViewController: FSPagingViewController) -> Int {
        0
    }
    
    func numberOfPages(in pagingViewController: FSPagingViewController) -> Int {
        childs.count
    }
    
    func pagingViewController(_ pagingViewController: FSPagingViewController, viewControllerForPageAt index: Int) -> UIViewController {
        childs[index]
    }
}
