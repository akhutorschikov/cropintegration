//
//  KHMainTopBar.swift
//  cropintegration
//
//  Created by Alex Khuala on 31.03.24.
//

import UIKit

class KHMainTopBar: KHView, KHColor_Sensitive
{
    // MARK: - Init
    
    init(with config: Config = .init())
    {
        self._config = config
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func updateColors()
    {
        self.backgroundColor = KHTheme.color.bar
        self._titleLabel?.textColor = KHTheme.color.text
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let view = self._titleLabel else {
            return
        }
        
        let size = view.estimatedSize
        
        if  options.contains(.sizeToFitHeight) {
            self.height = size.height + contentInset.height
        }
        
        let bounds = self.bounds.inset(contentInset)
        
        view.frame = bounds.inframe(size, .center).pixelRoundText()
    }
    
    // MARK: - Private
    
    private let _config: Config
    
    private weak var _titleLabel: KHLabel?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate()
    {
        self._addTitleLabel()
    }
    
    private func _addTitleLabel()
    {
        let label = KHLabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = KHStyle.headerFont
        label.text = "Demo Crop Editor"
        
        self.addSubview(label)
        self._titleLabel = label
    }
}
