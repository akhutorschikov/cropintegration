//
//  KHToastView.swift
//  kh-kit
//
//  Created by Alex Khuala on 20.05.23.
//

import UIKit

class KHToastView: KHView
{
    // MARK: - Types
    
    struct Config: KHConfig_Protocol
    {
        var textFont: UIFont?
        var borderWidth: CGFloat = 1
        var padding: UIEdgeInsets = .zero
        var cornerRadius: CGFloat = 5
    }
    
    // MARK: - Public
    
    var text: String?
    {
        didSet {
            self._textLabel?.text  = self.text
            self._plateView?.alpha = self.text?.count != 0 ? 1 : 0
            self.setNeedsLayout()
            
            if  UIView.inheritedAnimationDuration > 0 {
                self.layoutIfNeeded()
            }
        }
    }
    
    var backColor: UIColor?
    {
        didSet {
            self._plateView?.backgroundColor = self.backColor
        }
    }
    
    var borderColor: UIColor?
    {
        didSet {
            guard self._config.borderWidth > 0 else {
                return
            }
            
            self._plateView?.layer.borderColor = self.borderColor?.cgColor
        }
    }
    
    var textColor: UIColor?
    {
        didSet {
            self._textLabel?.textColor = self.textColor
        }
    }

    // MARK: - Init
    
    init(with config: Config)
    {
        self._config = config
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let label = self._textLabel, let container = self._plateView else {
            return
        }
        
        let bounds = self.bounds.inset(contentInset)
        let inset = self._config.padding.scale(-1)
        let estimatedSize = label.estimatedSize
        let containerSize = estimatedSize.inset(inset)
        
//        self._adjustContainerSize(&containerSize)
        
        let flexibleWidth = options.contains(.sizeToFitWidth)
        let flexibleHeight = options.contains(.sizeToFitHeight)
        
        if  flexibleWidth, flexibleHeight {
            container.frame = bounds.inframe(containerSize, [.top, .left]).pixelRound()
            self.size = container.size.inset(contentInset.scale(-1))
            
        } else if flexibleWidth {
            
            container.frame = bounds.inframe(containerSize, .top).pixelRound()
            self.height = container.bottom + contentInset.bottom
            
        } else if flexibleHeight {
            
            container.frame = bounds.inframe(containerSize, .left).pixelRound()
            self.width = container.right + contentInset.right
            
        } else {
            container.frame = bounds.inframe(containerSize, .center).pixelRound()
        }
        
        label.frame = container.bounds.inframe(estimatedSize, .center).pixelRoundText()
    }
    
    // MARK: - Private
    
    private var _config: Config
    
    private weak var _plateView: UIView?
    private weak var _textLabel: KHLabel?
    
    private var _cachedContainerWidth: CGFloat?
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._addPlateView()
        self._addTextLabel()
    }
    
    private func _addPlateView()
    {
        let view = UIView()
        view.backgroundColor = self.backColor
        view.layer.borderWidth = self._config.borderWidth
        view.layer.borderColor = self.borderColor?.cgColor
        view.clipsToBounds = true
        view.layer.cornerRadius = self._config.cornerRadius
        view.alpha = 0
        
        self.addSubview(view)
        self._plateView = view
    }

    private func _addTextLabel()
    {
        guard let container = self._plateView else {
            return
        }
        
        let label = KHLabel()
        label.textColor = self.textColor
        label.font = self._config.textFont
        label.textAlignment = .center
        
        container.addSubview(label)
        self._textLabel = label
    }
}
