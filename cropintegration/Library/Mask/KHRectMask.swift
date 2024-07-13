//
//  KHRectMask.swift
//  cropintegration
//
//  Created by Alex Khuala on 31.08.23.
//

import UIKit

class KHRectMask: UIView 
{
    init(with maskRect: CGRect = .zero)
    {
        self.maskRect = maskRect
        super.init(frame: .standard)
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var maskRect: CGRect
    {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill([rect])
        context.clear(self.maskRect)
    }
}
