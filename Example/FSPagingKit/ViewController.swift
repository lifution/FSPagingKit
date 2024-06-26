//
//  ViewController.swift
//  FSPagingKit
//
//  Created by Sheng on 11/03/2023.
//  Copyright (c) 2023 Sheng. All rights reserved.
//

import UIKit
import FSPagingKit

class ViewController: FSPagingViewController {
    
    // MARK: Properties/Private
    
    private let titlesView = FSPageTitlesView()
    
    private var caches = [UIViewController]()
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            delegate = titlesView
            dataSource = self
        }
        do {
            titlesView.titles = ["Latest", "TopList", "Random"].enumerated().compactMap { (_, text) in
                return FSPageTextTitle(text: text, transform: .scale)
            }
            titlesView.selectionHandler = { [weak self] index in
                guard let self = self else { return false }
                self.scrollToViewController(at: index, animated: true)
                return false
            }
            titlesView.layoutType = .equally
            titlesView.backgroundColor = .white
            view.addSubview(titlesView)
        }
        do {
            let tableVC = TableViewController()
            caches.append(tableVC)
            
            let yellowVC = UIViewController()
            yellowVC.view.backgroundColor = .yellow
            caches.append(yellowVC)
            
            let blueVC = UIViewController()
            blueVC.view.backgroundColor = .blue
            caches.append(blueVC)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        do {
            view.bringSubviewToFront(titlesView)
            let h: CGFloat = 40.0
            let y: CGFloat = view.safeAreaInsets.top
            titlesView.frame = .init(x: 0.0, y: y, width: view.bounds.width, height: h)
        }
        do {
            headerHeight = titlesView.frame.maxY
            stickyHeight = titlesView.frame.height + view.safeAreaInsets.top
//            contentInset.bottom = 100.0
        }
    }
}

extension ViewController: FSPagingViewControllerDataSource {
    
    func defaultPage(for pagingViewController: FSPagingViewController) -> Int {
        return 0
    }
    
    func numberOfPages(in pagingViewController: FSPagingViewController) -> Int {
        return caches.count
    }
    
    func pagingViewController(_ pagingViewController: FSPagingViewController, viewControllerForPageAt index: Int) -> UIViewController {
        return caches[index]
    }
}

