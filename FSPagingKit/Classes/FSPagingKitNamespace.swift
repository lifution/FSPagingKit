//
//  FSPagingKitNamespace.swift
//  FSPagingKit
//
//  Created by Sheng on 2023/11/3.
//  Copyright © 2023 Sheng. All rights reserved.
//

import UIKit
import Foundation

public struct FSPagingKitWrapper<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol FSPagingKitCompatible: AnyObject {}
extension FSPagingKitCompatible {
    public static var fspk: FSPagingKitWrapper<Self>.Type {
        get { return FSPagingKitWrapper<Self>.self }
        set {}
    }
    public var fspk: FSPagingKitWrapper<Self> {
        get { return FSPagingKitWrapper(self) }
        set {}
    }
}

extension UIViewController: FSPagingKitCompatible {}
