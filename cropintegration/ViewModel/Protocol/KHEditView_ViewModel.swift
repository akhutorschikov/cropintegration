//
//  KHEditView_ViewModel.swift
//  cropintegration
//
//  Created by Alex Khuala on 30.03.24.
//

import UIKit

protocol KHEditView_ViewModel 
{
    var contextMenuAnimationRegistry: KHAnimationBox.Registry? { get }
    var viewSizeRatio: CGFloat { get }
    var rotationAngleInDegrees: CGFloat { get }
    var orientationFlipped: Bool { get }
    var boundingFrame: CGRect? { get }
    
    func syncViewFrame()
    func capture(by editor: UIView & KHCropView_Delegate, and presentingView: UIView?) -> KHEditView_EditingState?
    func didCapture()
    func willRelease()
    func release()
    func restore() -> (KHCropRect, KHOrientation2)?
    
    func saveEditResult(_ result: KHEditResult)
}

protocol KHEditViewModel_Delegate: AnyObject
{
    func willBeginCapturingView(with identifier: Int?) -> KHEditContentViewSource?
    func didFinishReleasingView(with source: KHEditContentViewSource)
    
    // Optional: fix any visible inconsistency before and after animations
    func didFinishCapturingView(_ displayView: KHPhotoView)
    func willBeginReleasingView(_ displayView: KHPhotoView)
    
    func maskViewFrame(in view: UIView?) -> CGRect?
}

extension KHEditViewModel_Delegate
{
    func didFinishCapturingView(_ displayView: KHPhotoView) {}
    func willBeginReleasingView(_ displayView: KHPhotoView) {}
    
    func maskViewFrame(in view: UIView?) -> CGRect? { nil }
}

struct KHEditContentViewSource
{
    let displayView: KHPhotoView
    let editingView: KHPhotoView
    let placeholder: UIView
}

struct KHEditResult
{
    let cropRect: KHCropRect?
    let orientation: KHOrientation2?
    let reset: Bool
}

protocol KHEditView_EditingState
{
    var presentingView: UIView { get }
    var editingView: KHPhotoView { get }
    var displayView: KHPhotoView { get }
    var cropRectEditor: KHCropRect.Editor { get }
    var orientationEditor: KHOrientation2.Editor { get }
    
    func updateCropRect()
    func updateOrientation()
    func resetAllEdits()
    func refresh(cropRect: KHCropRect, orientation: KHOrientation2)

    func makeInnerResult() -> KHEditResult?
}


