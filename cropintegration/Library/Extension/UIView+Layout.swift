//
//  UIView+Layout.swift
//  kh-kit
//
//  Created by Alex Khuala on 31.03.24.
//

import UIKit

extension UIView 
{
    public func forceLayout()
    {
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
