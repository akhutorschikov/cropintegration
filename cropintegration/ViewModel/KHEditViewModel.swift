//
//  KHEditViewModel.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.03.24.
//

import UIKit

class KHEditViewModel: KHEditView_ViewModel
{
    init(delegate: KHEditViewModel_Delegate, viewIdentifier: Int? = nil, contextMenuAnimationRegistry: KHAnimationBox.Registry? = nil)
    {
        self._delegate = delegate
        self._identifier = viewIdentifier
        self.contextMenuAnimationRegistry = contextMenuAnimationRegistry
    }
    
    let contextMenuAnimationRegistry: KHAnimationBox.Registry?
    private(set) var viewSizeRatio: CGFloat = 1
    
    var rotationAngleInDegrees: CGFloat {
        
        guard let state = self._editingState else {
            return 0
        }
        
        let cropRotation = state.cropRectEditor.cropRect.angle
        let userRotation = KHCropRect.Editor.userRotation(from: cropRotation)
        
        return userRotation
    }
    
    var orientationFlipped: Bool {
        self._editingState?.orientationEditor.orientation.flipped == true
    }
    
    var boundingFrame: CGRect? {
        self._delegate?.maskViewFrame(in: self._editingState?.presentingView.superview)
    }
    
    func syncViewFrame()
    {
        guard let source = self._source, let container = source.displayView.superview else {
            return
        }
        
        let displayView = source.displayView
        let editingView = source.editingView
        let placeholder = source.placeholder
        
        if  container === placeholder.superview {
            displayView.frame = placeholder.frame
        } else {
            displayView.frame = container.convert(placeholder.frame, from: placeholder.superview)
        }
        displayView.layoutIfNeeded()
        
        editingView.frame = displayView.frame
        editingView.layoutIfNeeded()
        
        self.viewSizeRatio = displayView.frame.size.ratio
    }
    
    func capture(by editor: UIView & KHCropView_Delegate, and presentingView: UIView?) -> KHEditView_EditingState?
    {
        guard let delegate = self._delegate, let presentingView = presentingView, let source = delegate.willBeginCapturingView(with: self._identifier) else {
            return nil
        }
        self._source = source
        
        let displayView = source.displayView
        
        displayView.frame = editor.convert(displayView.frame, from: displayView.superview).pixelRound()
        displayView.layoutIfNeeded()
        
        presentingView.addSubview(displayView)
        
        self.viewSizeRatio = displayView.frame.size.ratio
        
        let editingView = source.editingView
        editingView.frame = displayView.frame
        editingView.layoutIfNeeded()
        
        editor.insertSubview(editingView, at: 0)
        
        // ------
        
        let cropRect = self._cropRectForEditing
        let orientation = self._orientationForEditing
        
        let cropRectEditor = KHCropRect.Editor(with: cropRect, minSize: 1)
        let orentationEditor = KHOrientation2.Editor(with: orientation)
        
        // ------ configure views
        
        editingView.orientation = orientation
        editingView.cropRect = cropRect
        
        displayView.orientation = orientation
        displayView.cropRect = cropRect
        
        // ------ store state
        
        let state = KHEditingState(presentingView: presentingView, editingView: editingView, displayView: displayView, cropRectEditor: cropRectEditor, orientationEditor: orentationEditor)
        
        self._editingState = state
        return state
    }
    
    func didCapture()
    {
        guard let view = self._source?.displayView else {
            return
        }
        self._delegate?.didFinishCapturingView(view)
    }
    
    func willRelease()
    {
        guard let view = self._source?.displayView else {
            return
        }
        
        self._delegate?.willBeginReleasingView(view)
    }
    
    func release()
    {
        guard let source = self._source else {
            return
        }
        
        let displayView = source.displayView
        let placeholder = source.placeholder
        
        displayView.frame = placeholder.frame
        placeholder.superview?.insertSubview(displayView, aboveSubview: placeholder)
        
        self._delegate?.didFinishReleasingView(with: source)
    }
    
    func restore() -> (KHCropRect, KHOrientation2)?
    {
        (self._cropRectForEditing, self._orientationForEditing)
    }
    
    func saveEditResult(_ result: KHEditResult)
    {
        let manager = KHContentManager.shared
        
        if  let cropRect = result.cropRect {
            manager.cropRect = cropRect
        } else if result.reset {
            manager.cropRect = nil
        }
        if  let orientation = result.orientation {
            manager.orientation = orientation
        } else if result.reset {
            
            // to avoid cases when photo orientation exists and makes visual difference
            // we need to rewrite current orientation anyway even if it is empty
                                
            let needsUpdate = manager.orientation != nil
            if  needsUpdate {
                
                let editor = KHOrientation2.Editor(with: manager.orientation)
                editor.reset(keepingRotation: true)
                
                let orientation = editor.orientation.nullify(!needsUpdate)
                manager.orientation = orientation
            }
        }
    }
    
    // MARK: - Private
    
    private var _source: KHEditContentViewSource?
    private weak var _delegate: KHEditViewModel_Delegate?
    private var _editingState: KHEditView_EditingState?
    
    private let _identifier: Int?
    
    private var _cropRectForEditing: KHCropRect {
        let manager = KHContentManager.shared
        return manager.cropRect ?? .init(maxSize: manager.imageFrame.size)
    }
    private var _orientationForEditing: KHOrientation2 {
        KHOrientation2.Editor(with: KHContentManager.shared.orientation).orientation
    }

}

// *************************
// *************************
// *************************


fileprivate class KHEditingState: KHEditView_EditingState
{
    init(presentingView: UIView, editingView: KHPhotoView, displayView: KHPhotoView, cropRectEditor: KHCropRect.Editor, orientationEditor: KHOrientation2.Editor)
    {
        self.presentingView = presentingView
        self.editingView = editingView
        self.displayView = displayView
        self.cropRectEditor = cropRectEditor
        self.orientationEditor = orientationEditor
    }
    
    let presentingView: UIView
    let editingView: KHPhotoView
    let displayView: KHPhotoView
    let cropRectEditor: KHCropRect.Editor
    let orientationEditor: KHOrientation2.Editor
    
    private(set) var changes: Set<Change> = []
    
    func updateCropRect()
    {
        self._updateViewCropRect()
        self.changes.insert(.cropRect)
    }
    
    func updateOrientation()
    {
        self._updateViewOrientation()
        self.changes.insert(.orientation)
    }
    
    func resetAllEdits()
    {
        self.cropRectEditor.reset(keepingFrameRatio: true)
        self.orientationEditor.reset(keepingRotation: true)
        self._updateViewCropRect()
        self._updateViewOrientation()
        self.changes = [.reset]
    }
    
    func refresh(cropRect: KHCropRect, orientation: KHOrientation2)
    {
        self.cropRectEditor.cropRect = cropRect
        self.orientationEditor.orientation = orientation
        self.displayView.cropRect = self.cropRectEditor.cropRect
        self.displayView.orientation = self.orientationEditor.orientation
        self.editingView.cropRect = self.cropRectEditor.cropRect
        self.editingView.orientation = self.orientationEditor.orientation
        self.changes = []
    }
    
    func makeInnerResult() -> KHEditResult?
    {
        guard !self.changes.isEmpty else {
            return nil
        }
        
        return .init(
            cropRect: self.changes.contains(.cropRect) ? self.cropRectEditor.cropRect : nil,
            orientation: self.changes.contains(.orientation) ? self.orientationEditor.orientation : nil,
            reset: self.changes.contains(.reset)
        )
    }
    
    enum Change
    {
        case cropRect
        case orientation
        case reset
    }
    
    // MARK: - Private
        
    private func _updateViewCropRect()
    {
        self.editingView.cropRect = self.cropRectEditor.cropRect
    }
    
    private func _updateViewOrientation()
    {
        self.editingView.orientation = self.orientationEditor.orientation
    }
}
