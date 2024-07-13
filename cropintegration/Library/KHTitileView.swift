//
//  KHTitleView.swift
//  kh-kit
//
//  Created by Alex Khuala on 26.12.22.
//

import UIKit

class KHTitleView: KHView
{
    var title: String?
    {
        didSet {
            self._titleLabel?.text = self.title
            self.setNeedsLayout()
        }
    }
    
    var subtitle: String?
    {
        didSet {
            
            if self.subtitle != nil {
                
                if self._subtitleLabel == nil {
                    self._addSubtitleView()
                }
                
                self._subtitleLabel?.text = self.subtitle
                
            } else {
                self._subtitleLabel?.removeFromSuperview()
                self._subtitleLabel = nil
            }
            
            self.setNeedsLayout()
        }
    }
    
    var titleColor: UIColor?
    {
        didSet {
            self._titleLabel?.textColor = self.titleColor
        }
    }
    
    var subtitleColor: UIColor?
    {
        didSet {
            self._subtitleLabel?.textColor = self.subtitleColor
        }
    }
    
    var maxWidth: CGFloat
    {
        let inset = self._config.padding
        let titleWidth = self._titleLabel?.estimatedSize.width.pixelRound(.up) ?? 0
        let subtitleWidth = self._subtitleLabel?.estimatedSize.width.pixelRound(.up) ?? 0
        
        return max(titleWidth, subtitleWidth) + inset.left + inset.right
    }
    
    // MARK: - Types
    
    struct Config: KHConfig_Protocol
    {
        var padding: UIEdgeInsets = .zero
        var titleFont: UIFont?
        var titleTextAlign: NSTextAlignment = .left
        var subtitleFont: UIFont?
        var subtitleTextAlign: NSTextAlignment = .left
        var clearance: CGFloat = 0
    }
    
    // MARK: - Init
    
    init(with config: Config = .init())
    {
        self._config = config
        super.init(frame: .standard)
        
        self._addTitleView()
    }
    
    override convenience init(frame: CGRect) {
        self.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: LayoutOptions)
    {
        let inset = self._config.padding.expand(to: contentInset)
        
        let contentBounds = self.bounds.inset(inset).top(0)
        var contentHeight: CGFloat = 0
        
        var titleHeight: CGFloat    = 18
        var subtitleHeight: CGFloat = 18
        
        if let label = self._titleLabel {
            titleHeight = label.estimatedSizeToFitWidth(contentBounds.width).height.pixelRound(.up)
            contentHeight += titleHeight
        }
        
        if let label = self._subtitleLabel {
            subtitleHeight = label.estimatedSizeToFitWidth(contentBounds.width).height.pixelRound(.up)
            contentHeight += subtitleHeight + self._config.clearance
        }
        
        var top = max(0, (contentBounds.height - contentHeight) / 2) + inset.top
        
        if let label = self._titleLabel {
            label.frame = contentBounds.inframe(.init(height: titleHeight), .top, .init(top: top)).pixelRoundText()
            top = label.bottom
        }
        
        if let label = self._subtitleLabel {
            label.frame = contentBounds.inframe(.init(height: subtitleHeight), .top, .init(top: top + self._config.clearance)).pixelRoundText()
            top = label.bottom
        }

        // check if we need to stretch view down
        if  contentHeight > contentBounds.height {
            self.size = .init(self.bounds.width, top + inset.bottom)
        }
    }
    
    // MARK: - Private
    
    private var _config: Config
    
    private weak var _titleLabel: KHLabel?
    private weak var _subtitleLabel: KHLabel?
    
    private func _addTitleView()
    {
        let label = KHLabel(.standard)
        label.numberOfLines = 0
        label.textAlignment = self._config.titleTextAlign
        label.textColor = self.titleColor
        label.font = self._config.titleFont
        
        self.addSubview(label)
        self._titleLabel = label
    }
    
    private func _addSubtitleView()
    {
        let label = KHLabel(.standard)
        label.numberOfLines = 0
        label.textAlignment = self._config.subtitleTextAlign
        label.textColor = self.subtitleColor
        label.font = self._config.subtitleFont
        
        self.addSubview(label)
        self._subtitleLabel = label
    }
}
