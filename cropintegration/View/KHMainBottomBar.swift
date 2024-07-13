//
//  KHMainBottomBar.swift
//  cropintegration
//
//  Created by Alex Khuala on 1.04.24.
//

import UIKit

protocol KHMainBottomBar_Delegate: AnyObject
{
    func bottomBarDidTapCropButton(_ bottomBar: KHMainBottomBar)
}

final class KHMainBottomBar: KHView, KHColor_Sensitive
{
    // MARK: - Init
    
    init(with delegate: KHMainBottomBar_Delegate, config: Config = .init())
    {
        self._config = config
        self._delegate = delegate
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
        if  let button = self._button {
            button.backgroundColor = KHTheme.color.buttonBack
            button.setTitleColor(KHTheme.color.button, for: .normal)
        }
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let button = self._button else {
            return
        }
        
        let size = button.size
        
        if  options.contains(.sizeToFitHeight) {
            self.height = size.height + contentInset.height
        }
        
        let bounds = self.bounds.inset(contentInset)
        
        button.frame = bounds.inframe(size, .center).pixelRoundText()
    }
    
    // MARK: - Private
    
    private let _config: Config
    private weak var _delegate: KHMainBottomBar_Delegate?
    
    private weak var _button: UIButton?
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._addButton()
    }
        
    private func _addButton()
    {
        let button = UIButton(type: .system)
        button.setTitle("Crop", for: .normal)
        button.titleLabel?.font = KHStyle.buttonFont
        button.addTarget(self, action: #selector(_didTap), for: .touchUpInside)
        button.size = KHStyle.cropButtonSize
        button.layer.cornerRadius = button.height / 2
        button.clipsToBounds = true

        self.addSubview(button)
        self._button = button
    }
    
    // MARK: - Actions
    
    @objc
    private func _didTap()
    {
        self._delegate?.bottomBarDidTapCropButton(self)
    }
}
