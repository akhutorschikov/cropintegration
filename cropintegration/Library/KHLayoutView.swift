//
//  KHLayoutView.swift
//  kh-kit
//
//  Created by Alex Khuala on 18.06.22.
//

import UIKit

class KHLayoutView: UIView, KHColor_Sensitive
{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
        self.populate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if  self._size != self.size || self._needs {
            self._size  = self.size
            self._needs = false
            
            self.layout(with: self.safeAreaInsets)
        }
    }
    
    final override func setNeedsLayout()
    {
        self._needs = true
        super.setNeedsLayout()
    }
        
    // MARK: - Overridable methods
    
    func layout(with contentInset: UIEdgeInsets)
    {
        
    }
    
    func configure()
    {
        
    }
    
    func populate()
    {
        
    }
    
    func updateColors()
    {
        
    }
    
    // MARK: - Internal
    
    private var _size: CGSize?
    private var _needs = true

}
