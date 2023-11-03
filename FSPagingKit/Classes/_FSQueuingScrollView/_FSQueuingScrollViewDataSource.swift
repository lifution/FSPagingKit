//
//  _FSQueuingScrollViewDataSource.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import Foundation

protocol _FSQueuingScrollViewDataSource: AnyObject {
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView, viewBefore view: UIView) -> UIView?
    func queuingScrollView(_ queuingScrollView: _FSQueuingScrollView, viewAfter view: UIView) -> UIView?
}
