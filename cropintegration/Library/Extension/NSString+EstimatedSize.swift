//
//  String+EstimatedSize.swift
//  kh-kit
//
//  Created by Alex Khuala on 3/1/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import UIKit

public extension NSString
{
    func estimatedSize(toFitWidth width: CGFloat, withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        let attributes = Self._makeAttributes(font: font, lineSpacing: lineSpacing)

        let textWidth = width > 0 ? width - inset.left - inset.right : CGFloat.greatestFiniteMagnitude;
        let size = self.boundingRect(with: KHSize(textWidth, .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context:nil).size;
        
        let w = width > 0 ? width : size.width.pixelRound(.up) + inset.left + inset.right;
        let h = size.height.pixelRound(.up) + inset.top + inset.bottom;
        
        return KHSize(w, h);
    }
    
    func estimatedSize(toFitHeight height: CGFloat, withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        let attributes = Self._makeAttributes(font: font, lineSpacing: lineSpacing)
        
        let textHeight = height > 0 ? height - inset.left - inset.right : CGFloat.greatestFiniteMagnitude;
        let size = self.boundingRect(with: KHSize(.greatestFiniteMagnitude, textHeight), options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size;
        
        let h = height > 0 ? height : size.height.pixelRound(.up) + inset.top + inset.bottom;
        let w = size.width.pixelRound(.up) + inset.left + inset.right;
    
        return KHSize(w, h);
    }

    func estimatedSize(withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        return self.estimatedSize(toFitWidth: 0, withFont: font, inset: inset, lineSpacing: lineSpacing);
    }
    
    // MARK: - Class private
    
    static private func _makeAttributes(font: UIFont, lineSpacing: CGFloat? = nil) -> [NSAttributedString.Key : Any]
    {
        var attributes: [NSAttributedString.Key : Any] = [.font: font]
        
        // line spacing
        if  let lineSpacing = lineSpacing {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            attributes[.paragraphStyle] = paragraphStyle
        }
        
        return attributes
    }
}

public extension NSAttributedString
{
    func estimatedSize(toFitWidth width: CGFloat, inset: KHInset) -> CGSize
    {
        let textWidth = width > 0 ? width - inset.left - inset.right : CGFloat.greatestFiniteMagnitude
        let size = self.boundingRect(with: .init(textWidth, .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
        
        let w = width > 0 ? width : size.width.pixelRound(.up) + inset.left + inset.right
        let h = size.height.pixelRound(.up) + inset.top + inset.bottom
        
        return KHSize(w, h)
    }
    
    func estimatedSize(toFitHeight height: CGFloat, inset: KHInset) -> CGSize
    {
        let textHeight = height > 0 ? height - inset.left - inset.right : CGFloat.greatestFiniteMagnitude;
        let size = self.boundingRect(with: KHSize(.greatestFiniteMagnitude, textHeight), options: .usesLineFragmentOrigin, context: nil).size;
        
        let h = height > 0 ? height : size.height.pixelRound(.up) + inset.top + inset.bottom;
        let w = size.width.pixelRound(.up) + inset.left + inset.right;
    
        return KHSize(w, h);
    }

    func estimatedSize(withFont font: UIFont, inset: KHInset, lineSpacing: CGFloat? = nil) -> CGSize
    {
        return self.estimatedSize(toFitWidth: 0, inset: inset)
    }
}
