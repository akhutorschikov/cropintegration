//
//  KHEditView.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.08.23.
//

import UIKit

class KHEditView: KHView
{
    init(with viewModel: KHEditView_ViewModel, config: Config = .init())
    {
        self._viewModel = viewModel
        self._config = config
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    struct Config: KHConfig_Protocol
    {
        var animationDuration: TimeInterval = 0.25
        var cropEditAlpha: CGFloat = 0.25
    }
    
    // MARK: - Public
    
    func willCapture()
    {
        guard let state = self._viewModel.capture(by: self, and: self._presentingView) else {
            return
        }
        
        state.editingView.cropViewMode = .editor(1)
        state.editingView.alpha = 0
        
        let cropView = KHCropView(with: state.cropRectEditor, delegate: self, config: .init(in: { c in
            c.lineWidth = KHPixel
        }))
        cropView.alpha = 0
        
        state.displayView.assignEditorView(cropView)
        
        self._state = state
        
        guard let maskFrame = self._viewModel.boundingFrame else {
            return
        }
        self._setMaskFrame(maskFrame, for: state.presentingView)
    }
    
    func animateCapture()
    {
        guard !self._editing else {
            return
        }
        self._editing = true
        
        if  let state = self._state {
            state.displayView.updateEditorView { $0.alpha = 1 }
            state.editingView.alpha = self._config.cropEditAlpha
            self._setMaskFrame(state.presentingView.frame, for: state.presentingView)
        }
        self.forceLayout()
    }
    
    func didCapture()
    {
        if  let state = self._state {
            state.presentingView.isHidden = true
            state.editingView.assignEditorView(from: state.displayView)
            state.editingView.cropViewMode = .editor(self._config.cropEditAlpha)
            state.editingView.alpha = 1
            self._removeMask(for: state.presentingView)
        }
        
        self._viewModel.didCapture()
    }
    
    func willRelese()
    {
        if  let state = self._state {
            state.presentingView.isHidden = false
            state.displayView.assignEditorView(from: state.editingView)
            state.displayView.orientation = state.editingView.orientation
            state.displayView.cropRect = state.editingView.cropRect
            
            state.displayView.layoutIfNeeded()
            
            state.editingView.alpha = self._config.cropEditAlpha
            state.editingView.cropViewMode = .editor(1)
            
            self._setMaskFrame(state.presentingView.frame, for: state.presentingView)
        }
        
        self._viewModel.willRelease()
    }
    
    func animateRelease(cancelled: Bool)
    {
        guard self._editing else {
            return
        }
        self._editing = false
        
        if  let state = self._state {
            if  cancelled, let (cropRect, orientation) = self._viewModel.restore() {
                state.refresh(cropRect: cropRect, orientation: orientation)
            }
            state.editingView.alpha = 0
            state.displayView.updateEditorView { $0.alpha = 0 }
            
            if  let maskFrame = self._viewModel.boundingFrame {
                self._setMaskFrame(maskFrame, for: state.presentingView)
            }
        }
        self.forceLayout()
    }
    
    func didRelease(cancelled: Bool)
    {
        guard let state = self._state else {
            return
        }
        self._state = nil
        self._viewModel.release()
        state.displayView.removeEditorView()
        
        if !cancelled, let result = state.makeInnerResult() {
            self._viewModel.saveEditResult(result)
        }
    }
    
    func cancelAllEvents()
    {
        self._state?.editingView.updateEditorView { ($0 as? KHCropView)?.cancelAllEvents() }
    }
    
    func beginRotationAngleEditing()
    {
        self._showToast()
    }
    
    func updateRotationAngle(_ angle: CGFloat, text: String)
    {
        guard let state = self._state else {
            return
        }
        
        state.cropRectEditor.rotate(angle)
        state.updateCropRect()
        
        self._setToastMessage(message: text)
    }
    
    func endRotationAngleEditing()
    {
        self._hideToast()
    }
    
    // MARK: - Actions
    
    func resetAllEdits()
    {
        self._state?.resetAllEdits()
        
        UIView.animate(withDuration: self._config.animationDuration) { [weak self] in
            self?._state?.editingView.layoutIfNeeded()
        }
    }
    
    func flip(vertically: Bool)
    {
        guard let state = self._state else {
            return
        }
        
        state.orientationEditor.flip(vertically: vertically)
        state.updateOrientation()
        
        UIView.animate(withDuration: self._config.animationDuration, delay: 0, options: .beginFromCurrentState) {
            state.editingView.layoutIfNeeded()
        }
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions) 
    {
        if  let view = self._presentingView {
            view.frame = self.bounds
        }
        
        guard let state = self._state else {
            return
        }
        
        guard self._editing else {
            self._viewModel.syncViewFrame()
            return
        }
        
        let frame = self.bounds.inframe(ratio: self._viewModel.viewSizeRatio, .center, contentInset).pixelRound()
        
        state.displayView.frame = frame
        state.editingView.frame = frame
    }
    
    // MARK: - Private
    
    private weak var _presentingView: UIView?
    
    private let _config: Config
    private let _viewModel: KHEditView_ViewModel
    
    private var _state: KHEditView_EditingState?
    private var _editing: Bool = false
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._addPresentingView()
    }
    
    private func _addPresentingView()
    {
        let view = UIView()
        view.isUserInteractionEnabled = false
        
        self.addSubview(view)
        self._presentingView = view
    }
    
    private func _setMaskFrame(_ maskFrame: CGRect, for view: UIView)
    {
        if  let mask = view.mask {
            mask.frame = maskFrame
            return
        }
            
        let mask = UIView(frame: maskFrame)
        mask.backgroundColor = .black
        
        view.mask = mask
    }
    
    private func _removeMask(for view: UIView)
    {
        view.mask = nil
    }
        
    private weak var _toastView: KHToastView?
    
    private func _showToast()
    {
        guard self._toastView == nil else {
            return
        }
        
        let view = KHToastView(with: .init(in: { c in
            c.textFont = KHStyle.digitFont
            c.padding = KHStyle.toastPadding
            c.borderWidth = 1
            c.cornerRadius = KHStyle.cornerRadius
        }))
        view.size = .init(1)
        view.backColor = KHTheme.color.back
        view.textColor = KHTheme.color.text
        view.borderColor = .black.withAlphaComponent(0.3)
        
        self.addSubview(view)
        self._toastView = view
    }
    
    func _setToastMessage(message: String)
    {
        guard let view = self._toastView else {
            return
        }
        
        UIView.performWithoutAnimation {
            
            view.text = message
            view.forceLayout(options: [.sizeToFitWidth, .sizeToFitHeight])
        }
        
        view.frame = self.bounds.inframe(view.size, .center).pixelRoundText()
    }

    
    private func _hideToast()
    {
        self._toastView?.removeFromSuperview()
        self._toastView = nil
    }
    
    // MARK: - System
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension KHEditView: KHCropView_Delegate
{
    func cropViewDidUpdateCropRect(_ cropView: KHCropView)
    {
        self._state?.updateCropRect()
    }
    
    func cropViewEventFrame(_ cropView: KHCropView) -> CGRect? 
    {
        cropView.convert(self.bounds, from: self)
    }    
}

