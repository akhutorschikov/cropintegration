//
//  KHLabel.swift
//  kh-kit
//
//  Created by Alex Khuala on 3/3/18.
//  Copyright © 2018 Alex Khuala. All rights reserved.
//

import UIKit

class KHLabel: UILabel, KHSizableToFit
{
    public var padding: KHInset?
    {
        didSet {
            self.setNeedsLayout();
        }
    }
    
    // MARK: - Drawing
    
    open override func drawText(in rect: CGRect)
    {
        var rect = rect;
        
        if let padding = self.padding {
            rect = rect.inset(padding);
        }
        
        super.drawText(in: rect);
    }
    
    // MARK: - Estimated size
    
    public func estimatedSizeToFitWidth(_ width: CGFloat) -> CGSize
    {
        if let text = self.text, let font = self.font {
            let inset = self.padding ?? KHInset(0);
            
            return text.estimatedSize(toFitWidth: width, withFont: font, inset: inset);
        }
        
        return KHSize(1);
    }
    
    public var estimatedSizeToFitWidth: CGSize
    {
        return self.estimatedSizeToFitWidth(self.width);
    }
    
    public func estimatedSizeToFitHeight(_ height: CGFloat) -> CGSize
    {
        if let text = self.text, let font = self.font {
            let inset = self.padding ?? KHInset(0);
            
            return text.estimatedSize(toFitHeight: height, withFont: font, inset: inset);
        }
        
        return KHSize(1);
    }
    
    public var estimatedSizeToFitHeight: CGSize
    {
        return self.estimatedSizeToFitHeight(self.height);
    }
    
    public var estimatedSize: CGSize
    {
        return self.estimatedSizeToFitWidth(0);
    }
    
    // MARK: - Size to fit
    
    open override func sizeToFit()
    {
        self.size = self.estimatedSize;
    }
    
    public func sizeToFitWidth(_ width: CGFloat? = nil)
    {
        self.size = self.estimatedSizeToFitWidth(width ?? self.width);
    }
    
    public func sizeToFitHeight(_ height: CGFloat? = nil)
    {
        self.size = self.estimatedSizeToFitHeight(height ?? self.height);
    }
}
