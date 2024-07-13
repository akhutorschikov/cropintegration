//
//  KHEditTopBar.swift
//  cropintegration
//
//  Created by Alex Khuala on 31.03.24.
//

import UIKit

protocol KHEditTopBar_Delegate: AnyObject
{
    func topBarDidTapCancelButton(_ topBar: KHEditTopBar)
    func topBarDidTapFlipHorButton(_ topBar: KHEditTopBar)
    func topBarDidTapFlipVerButton(_ topBar: KHEditTopBar)
    func topBarDidTapResetButton(_ topBar: KHEditTopBar)
    func topBarDidTapDoneButton(_ topBar: KHEditTopBar)
}

final class KHEditTopBar: KHView, KHColor_Sensitive
{
    // MARK: - Init
    
    init(with delegate: KHEditTopBar_Delegate, config: Config = .init())
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
        self._entries.forEach { $0.view?.updateColors() }
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        self.floatLayout(entries: self, contentInset: contentInset, options: .sizeToFitHeight)
    }
    
    // MARK: - Private
    
    private let _config: Config
    private var _entries: [Entry] = []
    private weak var _delegate: KHEditTopBar_Delegate?
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._entries.append(.init(view: self._addTextButton(title: "Cancel", action: { [weak self] in
            guard let self = self else {
                return
            }
            self._delegate?.topBarDidTapCancelButton(self)
        })))
        self._entries.append(.init(view: self._addGroupView()))
        self._entries.append(.init(view: self._addTextButton(title: "Done", action: { [weak self] in
            guard let self = self else {
                return
            }
            self._delegate?.topBarDidTapDoneButton(self)
        })))
    }
    
    private func _addTextButton(title: String, action: @escaping () -> Void) -> KHInternalTextButton
    {
        let view = KHInternalTextButton(with: title)
        view.action = action
        
        self.addSubview(view)
        return view
    }
    
    private func _addGroupView() -> KHInternalGroupView
    {
        let view = KHInternalGroupView(with: self)
        view.size = KHStyle.buttonSize
        view.forceLayout(KHStyle.buttonGroupInset, options: .sizeToFitWidth)
        view.layer.cornerRadius = view.height / 2
        
        self.addSubview(view)
        return view
    }
    
    private struct Entry
    {
        weak var view: (KHEditTopBar_EntryView & KHColor_Sensitive)?
    }
}

extension KHEditTopBar: KHViewFloatLayout_Entries
{
    func enumerate(in block: (KHViewFloatLayoutEntry) -> Void) 
    {
        for (index, entry) in self._entries.enumerated() {
            guard let view = entry.view else {
                return
            }
            block(.init(identifier: index, view: view, minWidth: view.minWidth, spacingLeft: .minimum(10)))
        }
    }
}

extension KHEditTopBar: KHInternalGroupView_Delegate
{
    fileprivate func groupView(_ view: KHInternalGroupView, didRequestActionWithType type: KHInternalImageButton.ButtonType)
    {
        guard let delegate = self._delegate else {
            return
        }
        
        switch type {
        case .flipHor:
            delegate.topBarDidTapFlipHorButton(self)
        case .flipVer:
            delegate.topBarDidTapFlipVerButton(self)
        case .reset:
            delegate.topBarDidTapResetButton(self)
        }
    }
}

fileprivate protocol KHEditTopBar_EntryView: KHView
{
    var minWidth: CGFloat { get }
}

// *************************
// *************************   GROUP VIEW
// *************************

fileprivate protocol KHInternalGroupView_Delegate: AnyObject
{
    func groupView(_ view: KHInternalGroupView, didRequestActionWithType type: KHInternalImageButton.ButtonType)
}

fileprivate class KHInternalGroupView: KHEventTransparentView, KHColor_Sensitive, KHEditTopBar_EntryView
{
    // MARK: - Init
    
    init(with delegate: KHInternalGroupView_Delegate, config: Config = .init())
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
        self.backgroundColor = KHTheme.color.back
        self._entries.forEach { $0.view?.updateColors() }
    }
    
    var minWidth: CGFloat {
        self.width
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        self.floatLayout(entries: self, contentInset: contentInset, options: .sizeToFitWidth)
    }
    
    // MARK: - Private
    
    private let _config: Config
    private var _entries: [Entry] = []
    private weak var _delegate: KHInternalGroupView_Delegate?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate()
    {
        var entries: [Entry] = []
        for type in KHInternalImageButton.ButtonType.allCases {
            entries.append(.init(view: self._addButton(type: type)))
        }
        self._entries = entries
    }
    
    private func _addButton(type: KHInternalImageButton.ButtonType) -> KHInternalImageButton
    {
        let view = KHInternalImageButton(with: type)
        view.action = { [weak self] in
            guard let self = self else {
                return
            }
            self._delegate?.groupView(self, didRequestActionWithType: type)
        }
        
        self.addSubview(view)
        return view
    }
    
    private struct Entry
    {
        weak var view: (KHEditTopBar_EntryView & KHColor_Sensitive)?
    }
}

extension KHInternalGroupView: KHViewFloatLayout_Entries
{
    func enumerate(in block: (KHViewFloatLayoutEntry) -> Void) 
    {
        let spacing = KHStyle.buttonGroupSpacing
        for (index, entry) in self._entries.enumerated() {
            guard let view = entry.view else {
                return
            }
            block(.init(identifier: index, view: view, minWidth: view.minWidth, spacingLeft: .constant(spacing)))
        }
    }
}

// *************************
// *************************   TEXT BUTTON
// *************************

fileprivate class KHInternalTextButton: KHView, KHColor_Sensitive, KHEditTopBar_EntryView
{
    // MARK: - Init
    
    init(with title: String, config: Config = .init())
    {
        self._config = config
        super.init(frame: .standard)
        self._configure()
        self._populate(title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func updateColors()
    {
        self.backgroundColor = KHTheme.color.bar
        self._button?.setTitleColor(KHTheme.color.text, for: .normal)
    }
    
    var action: (() -> Void)?
    
    var minWidth: CGFloat {
        self._button?.width ?? 44
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let view = self._button else {
            return
        }
        
        let size = view.size
        
        if  options.contains(.sizeToFitHeight) {
            self.height = size.height + contentInset.height
        }
        
        let bounds = self.bounds.inset(contentInset)
        
        view.frame = bounds.inframe(size, .center).pixelRoundText()
        
        self.layer.cornerRadius = self.height / 2
    }
    
    // MARK: - Private
    
    private let _config: Config
    
    private weak var _button: UIButton?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate(_ title: String)
    {
        self._addButton(title)
    }
    
    private func _addButton(_ title: String)
    {
        let button = KHInternalButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(_didTap), for: .touchUpInside)
        button.size = KHStyle.buttonSize

        self.addSubview(button)
        self._button = button
    }
    
    // MARK: - Action
    
    @objc
    private func _didTap()
    {
        self.action?()
    }
    
    // MARK: - Event
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        guard let button = self._button else {
            return super.point(inside: point, with: event)
        }
        return button.point(inside: self.convert(point, to: button), with: event)
    }
}


// *************************
// *************************   IMAGE BUTTON
// *************************

fileprivate class KHInternalImageButton: KHView, KHColor_Sensitive, KHEditTopBar_EntryView
{
    // MARK: - Init
    
    init(with type: ButtonType, config: Config = .init())
    {
        self.buttonType = type
        self._config = config
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    var buttonType: ButtonType
    
    func updateColors()
    {
        self.backgroundColor = KHTheme.color.bar
        self._button?.tintColor = KHTheme.color.main
    }
    
    var action: (() -> Void)?
    
    var minWidth: CGFloat {
        self._button?.width ?? 44
    }
    
    struct Config: KHConfig_Protocol
    {
        //
    }
    
    enum ButtonType: CaseIterable
    {
        case flipHor
        case flipVer
        case reset
        
        var icon: String {
            switch self {
            case .flipHor:    "b-flip-hor"
            case .flipVer:    "b-flip-ver"
            case .reset:      "b-reset"
            }
        }
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        guard let view = self._button else {
            return
        }
        
        let size = view.size
        
        if  options.contains(.sizeToFitHeight) {
            self.height = size.height + contentInset.height
        }
        
        let bounds = self.bounds.inset(contentInset)
        
        view.frame = bounds.inframe(size, .center).pixelRoundText()
        
        self.layer.cornerRadius = self.height / 2
    }
    
    // MARK: - Private
    
    private let _config: Config
    
    private weak var _button: UIButton?
    
    private func _configure()
    {
        self.clipsToBounds = true
    }
    
    private func _populate()
    {
        self._addButton()
    }
    
    private func _addButton()
    {
        let button = KHInternalButton(type: .system)
        button.setImage(.init(named: self.buttonType.icon), for: .normal)
        button.addTarget(self, action: #selector(_didTap), for: .touchUpInside)
        button.sizeToFit()

        self.addSubview(button)
        self._button = button
    }
    
    // MARK: - Action
    
    @objc
    private func _didTap()
    {
        self.action?()
    }
    
    // MARK: - Event
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool 
    {
        guard let button = self._button else {
            return super.point(inside: point, with: event)
        }
        return button.point(inside: self.convert(point, to: button), with: event)
    }
}

// *************************
// *************************   EXTENDING BUTTON TOUCH BOUNDS TO MIN 44 x 44 PT
// *************************


fileprivate class KHInternalButton: UIButton
{
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool 
    {
        !self.isHidden && self.alpha > 0.01 && KHViewHelper.eventFrame(for: self.bounds, with: .init(44)).contains(point)
    }
}
