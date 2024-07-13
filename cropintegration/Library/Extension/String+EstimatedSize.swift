//
//  String+EstimatedSize.swift
//  kh-timer
//
//  Created by Alex Khuala on 3/2/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import Foundation
import UIKit

public extension String
{
    func estimatedSize(toFitWidth width: CGFloat, withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        return (self as NSString).estimatedSize(toFitWidth: width, withFont: font, inset: inset, lineSpacing: lineSpacing)
    }
    
    func estimatedSize(toFitHeight height: CGFloat, withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        return (self as NSString).estimatedSize(toFitHeight: height, withFont: font, inset: inset, lineSpacing: lineSpacing)
    }
    
    func estimatedSize(withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        return (self as NSString).estimatedSize(withFont: font, inset: inset, lineSpacing: lineSpacing)
    }
}
