//
//  KHViewHelper.swift
//  cropintegration
//
//  Created by Alex Khuala on 31.03.24.
//

import UIKit

class KHViewHelper
{
    static let animationDuration: TimeInterval = 0.25
    
    // MARK: - Event Frame
    
    static func eventFrame(for frame: CGRect, with minEventSize: CGSize?, eventInset: UIEdgeInsets? = nil) -> CGRect
    {
        var inset: UIEdgeInsets = .zero
        var needsUpdate = false
        
        if  let minSize = minEventSize {
            if  frame.size.width < minSize.width {
                inset.x = (frame.size.width - minSize.width) / 2
                needsUpdate = true
            }
            if  frame.size.height < minSize.height {
                inset.y = (frame.size.height - minSize.height) / 2
                needsUpdate = true
            }
        }
        
        if  let eventInset = eventInset {
            inset = inset + eventInset
            needsUpdate = true
        }
        
        guard needsUpdate else {
            return frame
        }
        
        return frame.inset(inset)
    }
    
    // MARK: - Corner Radius
    
    static func setCornerRadius(_ cornerRadius: CGFloat, to view: UIView)
    {
        var result: CGFloat = 0
        let minSize = view.size.minSize
        if  cornerRadius > 0.5 {
            result = min(cornerRadius, minSize / 2)
        } else if cornerRadius > 0 {
            result = minSize * cornerRadius
        }
        if  view.layer.cornerRadius != result {
            view.layer.cornerRadius  = result
        }
    }
}
