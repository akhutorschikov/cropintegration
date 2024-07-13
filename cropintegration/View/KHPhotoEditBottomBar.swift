//
//  KHPhotoEditBottomBar.swift
//  cropintegration
//
//  Created by Alex Khuala on 1.09.23.
//

import UIKit

protocol KHPhotoEditBottomBar_Delegate: AnyObject
{
    func photoEditBottomBarWillBeginEditing() // optional
    func photoEditBottomBarDidFinishEditing() // optional
    
    func photoEditBottomBarDidChangeRotationAngle(_ rotationAngleInDegrees: CGFloat, text: String)
}

extension KHPhotoEditBottomBar_Delegate
{
    func photoEditBottomBarWillBeginEditing() {}
    func photoEditBottomBarDidFinishEditing() {}
}

class KHPhotoEditBottomBar: KHView, KHColor_Sensitive
{
    init(with delegate: KHPhotoEditBottomBar_Delegate)
    {
        self._delegate = delegate
        super.init(frame: .standard)
        self._configure()
        self._populate()
    }
    
    // MARK: - Public
    
    var rotationAngleInDegrees: CGFloat
    {
        get {
            self._slider?.value ?? 0
        }
        set {
            self._slider?.value = newValue
        }
    }
    
    var orientationFlipped: Bool
    {
        get {
            self._slider?.flipped ?? false
        }
        set {
            self._slider?.flipped = newValue
        }
    }
    
    func updateColors() 
    {
        self._slider?.mainColor = KHTheme.color.cropSlider
    }
    
    func cancelAllEvents()
    {
        self._slider?.cancelAllEvents()
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions) 
    {
        let bounds = self.bounds.inset(contentInset)
        
        if  let view = self._slider {
            view.frame = bounds.pixelRound()
        }
    }
    
    // MARK: - Private
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _configure()
    {
        
    }
    
    private func _populate()
    {
        self._addDashSlider()
    }
    
    private func _addDashSlider()
    {
        let inputData: KHDashSlider.InputData = .init(minValue: 0, maxValue: 360, interval: 1)
        
        let view = KHDashSlider(with: inputData, delegate: self, config: .init(in: { c in
            c.lineWidth = 1
            c.accuracy = 0.1
            c.infinite = true
            c.unitSize = .init(12)
            c.textFont = KHStyle.digitFont
            c.textFormat = " %0.1f°"
            c.invertedTextValueWhenFlipped = true
        }))
        
        self.addSubview(view)
        self._slider = view
    }
    
    private weak var _slider: KHDashSlider?
    private weak var _delegate: KHPhotoEditBottomBar_Delegate?
}

extension KHPhotoEditBottomBar: KHDashSlider_Delegate
{
    func dashSliderWillBeginUpdates(_ slider: KHDashSlider)
    {
        slider.textLabelEnabled = false
        self._delegate?.photoEditBottomBarWillBeginEditing()
    }
    
    func dashSlider(_ slider: KHDashSlider, didChangeValueWhileScrolling scrolling: Bool)
    {
        self._delegate?.photoEditBottomBarDidChangeRotationAngle(slider.value, text: slider.text)
    }
    
    func dashSliderDidFinishUpdates(_ slider: KHDashSlider)
    {
        slider.textLabelEnabled = true
        self._delegate?.photoEditBottomBarDidFinishEditing()
    }
}
