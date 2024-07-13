//
//  KHEditController.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.08.23.
//

import UIKit

protocol KHEditController_Delegate: AnyObject
{
    func editControllerDidFinish(controller: KHEditController, cancelled: Bool)
}

class KHEditController: KHController<KHEditLayoutView>
{
    init(with viewModel: KHEditView_ViewModel, delegate: KHEditController_Delegate)
    {
        self._viewModel = viewModel
        self._delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit 
    {
        self.unregisterForThemeUpdates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        .darkContent
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.layoutView.setView(KHEditView(with: self._viewModel, config: .init(in: { c in
            c.animationDuration = KHViewHelper.animationDuration
        })), for: .editor)
        self.layoutView.setView(KHEditTopBar(with: self), for: .topBar)
        self.layoutView.setView(KHPhotoEditBottomBar(with: self), for: .bottomBar)
        
        self.registerForThemeUpdates()
    }
    
    public func show()
    {
        guard let editView = self._editView, !self._captured else {
            return
        }
        self._captured = true
        self.view.layoutIfNeeded()
        
        editView.willCapture()
        
        let animation: KHAnimationBox.Animation = { [weak self] in
            self?.layoutView.editing = true
        }
        let completion: KHAnimationBox.Completion = { [weak self] in
            guard let editView = self?._editView else {
                return
            }
            editView.didCapture()
        }
        
        if  let registry = self._viewModel.contextMenuAnimationRegistry {
            
            // context menu already animating photo view so we need
            // to put it into final state without any extra animation
            editView.animateCapture()
            
            // add animation / completion to registry
            registry.addAnimation(animation)
            registry.addCompletion(completion)
            
        } else {
            UIView.animate(withDuration: KHViewHelper.animationDuration) { [weak self] in
                self?._editView?.animateCapture()
                animation()
            } completion: { _ in
                completion()
            }
        }
        
        self._updateBottomBar()
    }
    
    private weak var _delegate: KHEditController_Delegate?
    private var _viewModel: KHEditView_ViewModel
    private var _captured: Bool = false
    
    private var _editView: KHEditView?
    {
        self.layoutView.view(with: .editor) as? KHEditView
    }
    
    private var _bottomBar: KHPhotoEditBottomBar?
    {
        self.layoutView.view(with: .bottomBar) as? KHPhotoEditBottomBar
    }
    
    private func _finish(cancelled: Bool)
    {
        self._bottomBar?.cancelAllEvents()
        
        guard let editView = self._editView, self._captured else {
            self._didFinish(cancelled: cancelled)
            return
        }
        
        editView.cancelAllEvents()
        editView.willRelese()
        
        UIView.animate(withDuration: KHViewHelper.animationDuration, delay: 0) { [weak self] in
            self?.layoutView.editing = false
            guard let editView = self?._editView else {
                return
            }
            editView.animateRelease(cancelled: cancelled)
        } completion: { [weak self] _ in
            self?._editView?.didRelease(cancelled: cancelled)
            self?._didFinish(cancelled: cancelled)
        }
    }
    
    private func _didFinish(cancelled: Bool)
    {
        self._delegate?.editControllerDidFinish(controller: self, cancelled: cancelled)
    }
    
    private func _updateBottomBar()
    {
        self._bottomBar?.rotationAngleInDegrees = self._viewModel.rotationAngleInDegrees
        self._updateBottomBarFlipped()
    }
    
    private func _updateBottomBarFlipped()
    {
        self._bottomBar?.orientationFlipped = self._viewModel.orientationFlipped
    }
    
    private func _resetAllEdits()
    {
        guard let editView = self._editView else {
            return
        }
        editView.resetAllEdits()
        self._updateBottomBar()
    }
    
    private func _flip(vertically: Bool)
    {
        guard let editView = self._editView else {
            return
        }
        editView.flip(vertically: vertically)
        self._updateBottomBarFlipped()
    }
}

extension KHEditController: KHTheme_Sensitive
{
    typealias Theme = KHTheme
    
    func didChangeTheme() 
    {
        self.layoutView.updateColors()
    }
}

extension KHEditController: KHEditTopBar_Delegate
{
    func topBarDidTapCancelButton(_ topBar: KHEditTopBar) 
    {
        self._finish(cancelled: true)
    }
    
    func topBarDidTapFlipHorButton(_ topBar: KHEditTopBar) 
    {
        self._flip(vertically: false)
    }
    
    func topBarDidTapFlipVerButton(_ topBar: KHEditTopBar) 
    {
        self._flip(vertically: true)
    }
    
    func topBarDidTapResetButton(_ topBar: KHEditTopBar) 
    {
        self._resetAllEdits()
    }
    
    func topBarDidTapDoneButton(_ topBar: KHEditTopBar) 
    {
        self._finish(cancelled: false)
    }
}

extension KHEditController: KHPhotoEditBottomBar_Delegate
{
    func photoEditBottomBarWillBeginEditing() 
    {
        self._editView?.beginRotationAngleEditing()
    }
    
    func photoEditBottomBarDidFinishEditing() 
    {
        self._editView?.endRotationAngleEditing()
    }
    
    func photoEditBottomBarDidChangeRotationAngle(_ rotationAngleInDegrees: CGFloat, text: String)
    {
        let cropRotation = KHCropRect.Editor.cropRotation(from: rotationAngleInDegrees)
        self._editView?.updateRotationAngle(cropRotation, text: text)
    }
}
