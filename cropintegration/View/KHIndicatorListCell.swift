//
//  KHIndicatorListCell.swift
//  kh-kit
//
//  Created by Alex Khuala on 23.05.23.
//

import UIKit

class KHIndicatorListCell: KHListView_Cell
{
    enum IndicatorType
    {
        case normal
        case checkbox
        case container
    }
    
    let minWidth: CGFloat = KHStyle.listInset.left
    
    func createView() -> KHView
    {
        let view = KHIndicatorListView(with: self._type)
        view.active = self._active
        
        self._view = view
        return view
    }
    
    func didChangeState(_ state: [any KHListView_Mod], adding: [any KHListView_Mod], removing: [any KHListView_Mod])
    {
        self._active = self._activeMod?.isFound(in: state) == true
    }
    
    func updateColors(selected: Bool)
    {
        self._view?.updateColors()
    }
    
    init(with type: IndicatorType, activeMod: (any KHListView_Mod)? = nil)
    {
        self._type = type
        self._activeMod = activeMod
    }
    
    // MARK: - Private
    
    private var _type: IndicatorType
    private weak var _view: KHIndicatorListView?
    
    private var _active = false
    {
        didSet {
            self._view?.active = self._active
        }
    }
    private var _activeMod: (any KHListView_Mod)?
}


// *************************
// *************************
// *************************


fileprivate class KHIndicatorListView: KHView
{
    typealias IndicatorType = KHIndicatorListCell.IndicatorType
    
    // MARK: - Public
    
    func updateColors()
    {
        self._checkboxView?.updateColors()
        self._updateArrowColors()
    }
    
    var active: Bool = false
    {
        didSet {
            guard self.active != oldValue else {
                return
            }
            
            switch self._type {
            case .normal:
                
                if  self.active {
                    self._addCheckboxView(checked: self.active, updateColors: true)
                } else {
                    self._removeCheckboxView()
                }
                
            case .container:
                self._updateArrowRotation()
                
            case .checkbox:
                self._checkboxView?.checked = self.active
            }
        }
    }
    
    // MARK: - Init
    
    init(with type: IndicatorType)
    {
        self._type = type
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
        let bounds = self.bounds.inset(contentInset)
        let inset: UIEdgeInsets = .init(left: 3)
        
        if  let view = self._checkboxView {
            view.frame = bounds
            view.forceLayout(inset)
        }
        
        if  let view = self._arrowView {
            view.frame = bounds.inframe(view.size, .left, inset)
        }
    }
    
    // MARK: - Private
    
    private var _type: IndicatorType
    
    private weak var _checkboxView: KHIndicatorCheckboxView?
    private weak var _arrowView: UIView?
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        switch self._type {
        case .checkbox:
            self._addCheckboxView()
        case .container:
            self._addArrowView()
        default:
            break
        }
    }
    
    private func _addCheckboxView(checked: Bool = false, updateColors: Bool = false)
    {
        guard self._checkboxView == nil else {
            return
        }
        
        let view = KHIndicatorCheckboxView(with: .init(in: { c in
            c.squareWidth = 36
            c.borderWidth = 5
        }))
        view.checked = checked
        
        if  updateColors {
            view.updateColors()
        }
        
        self.addSubview(view)
        self._checkboxView = view
    }
    
    private func _addArrowView()
    {
        let view = UIImageView(image: .init(named: "list-arrow-icon"))
        
        self.addSubview(view)
        self._arrowView = view
    }
    
    private func _removeCheckboxView()
    {
        self._checkboxView?.removeFromSuperview()
        self._checkboxView = nil
    }
    
    private func _updateArrowColors()
    {
        guard let view = self._arrowView else {
            return
        }
        view.tintColor = KHTheme.color.main
    }
    
    private func _updateArrowRotation()
    {
        guard let view = self._arrowView else {
            return
        }
        
        if  self.active {
            view.transform = .init(rotationAngle: .pi / 2)
        } else {
            view.transform = .identity
        }
    }
}


// *************************
// *************************
// *************************


fileprivate class KHIndicatorCheckboxView: KHView, KHColor_Sensitive
{
    // MARK: - Types
    
    struct Config: KHConfig_Protocol
    {
        var squareWidth: CGFloat = 8
        var borderWidth: CGFloat = 1.5
    }
    
    // MARK: - Public
    
    func updateColors() 
    {
        guard let view = self._squareView else {
            return
        }
        
        if  self.checked {
            view.backgroundColor = KHTheme.color.active
            view.layer.borderColor = UIColor.clear.cgColor
        } else {
            view.backgroundColor = .clear
            view.layer.borderColor = KHTheme.color.passive.cgColor
        }
    }
    
    var checked: Bool = false
        
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
        let bounds = self.bounds.inset(contentInset)
        
        if  let view = self._squareView {
            view.frame = bounds.inframe(view.size, .left).pixelRound()
        }
    }
    
    // MARK: - Private
    
    private var _config: Config
    private weak var _squareView: KHView?
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._addSquareView()
    }
    
    private func _addSquareView()
    {
        let view = KHView(KHSize(self._config.squareWidth).bounds)
        view.layer.borderWidth = self._config.borderWidth.pixelRound()
        
        self.addSubview(view)
        self._squareView = view
    }
}
