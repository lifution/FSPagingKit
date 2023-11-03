//
//  FSPageViewControllerDataSource.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

public protocol FSPageViewControllerDataSource: AnyObject {
    func pageViewController(_ pageViewController: FSPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    func pageViewController(_ pageViewController: FSPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
}
