//
//  KHCropMask2.swift
//  kh-editor2
//
//  Created by Alex Khuala on 5/20/19.
//  Copyright © 2019 Alex Khuala. All rights reserved.
//

import UIKit

class KHCropMask: UIView
{
    override var alpha: CGFloat
        {
        get {
            return self._maskView.alpha
        }
        set {
            self._maskView.alpha = newValue
        }
    }
    
    init(_ frame: CGRect, _ alpha: CGFloat = 0.5)
    {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.orange
        self.isUserInteractionEnabled = false
        
        let maskView = UIView(self.bounds.inset(KHInset(-5000)))
        maskView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin]
        maskView.backgroundColor = UIColor.black
        maskView.alpha = alpha
        
        self.addSubview(maskView)
        self._maskView = maskView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal
    
    private weak var _maskView: UIView!
}
