//
//  KHSizableToFit.swift
//  kh-kit
//
//  Created by Alex Khuala on 10/28/18.
//

import UIKit

public protocol KHSizableToFit: UIView {
    
    func estimatedSizeToFitWidth(_ width: CGFloat) -> CGSize
    var  estimatedSizeToFitWidth: CGSize { get }
    func estimatedSizeToFitHeight(_ height: CGFloat) -> CGSize
    var  estimatedSizeToFitHeight: CGSize { get }
    var  estimatedSize: CGSize { get }
    func sizeToFit()
    func sizeToFitWidth(_ width: CGFloat?)
    func sizeToFitHeight(_ height: CGFloat?)
}
