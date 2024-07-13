//
//  KHCropView.swift
//  cropintegration
//
//  Created by Alex Khuala on 28.08.23.
//

import UIKit

protocol KHCropView_Delegate: AnyObject
{
    func cropViewDidUpdateCropRect(_ cropView: KHCropView)
    
    func cropViewWillBeginMoving(_ cropView: KHCropView) // optional
    func cropViewDidFinishMoving(_ cropView: KHCropView) // optional
    
    func cropViewWillBeginScaling(_ cropView: KHCropView) // optional
    func cropViewDidFinishScaling(_ cropView: KHCropView) // optional
    
    func cropViewEventFrame(_ cropView: KHCropView) -> CGRect? // optional
}

class KHCropView: KHView, KHColor_Sensitive
{
    let coordinator: KHCropRect.Editor
    
    // MARK: - Init
    
    init(with coordinator: KHCropRect.Editor, delegate: KHCropView_Delegate, config: Config)
    {
        self.coordinator = coordinator
        self._config = config
        self._delegate = delegate
        
        super.init(frame: .standard)
        
        self._configure()
        self._populate()
        self.updateColors()
    }
    
    // MARK: - Methods
    
    func updateColors()
    {
        let mainColor = KHTheme.color.cropLineMain
        let nextColor = KHTheme.color.cropLineNext
        
        for (_, entries) in self._lineEntries {
            for entry in entries {
                entry.view?.backgroundColor = entry.main ? mainColor : nextColor
            }
        }
        
        self._borderView?.layer.borderColor = mainColor.cgColor
    }
        
    func cancelAllEvents()
    {
        self._decelerator.stop()
        self._stopPanning()
        self._stopPinching()
    }
    
    // MARK: - Types
    
    struct Config: KHConfig_Protocol
    {
        var lineWidth: CGFloat = 1
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        let bounds = self.bounds
        
        if  let view = self._borderView {
            view.frame = bounds
        }
        
        self._updateLinesFrame(with: bounds)
        self._syncScale()
    }
    
    private func _updateLinesFrame(with bounds: CGRect)
    {
        let d = self._config.lineWidth
        for (axis, entries) in self._lineEntries {
            
            let bounds = axis.geometry.components(of: bounds)
            for entry in entries {
                
                guard let view = entry.view else {
                    continue
                }
                
                let a = bounds.main.origin + entry.formula(bounds.main.size, d)
                let b = bounds.next.origin + d
                let s = bounds.next.size - 2 * d
                
                let origin: CGPoint = axis.geometry.restore(from: .init(a, b))
                let size: CGSize = axis.geometry.restore(from: .init(d, s))
                
                view.frame = .init(origin, size).pixelRound()
            }
        }
    }
    
    // MARK: - Private
    
    private var _config: Config
    private weak var _delegate: KHCropView_Delegate?
    private weak var _borderView: UIView?
    private var _lineEntries: [Axis: [LineEntry]] = [:]
    
    private var _scale: CGPoint = .init(1)
    private var _minSize: CGSize
    {
        .init(11).scale(self._scale)
    }
    
    private var _panning: Bool = false
    private var _pinching: Bool = false
    
    private lazy var _panGesture = UIPanGestureRecognizer(target: self, action: #selector(_didPan(_:)))
    private lazy var _pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(_didPinch(_:)))
    
    private lazy var _decelerator = KHDecelerator(delegate: self, config: .init(in: { c in
        c.attenuation = 0.8
    }))
    
    private func _configure()
    {
        self._addGestureRecognizers([self._panGesture, self._pinchGesture])
    }
    
    private func _populate()
    {
        self._addBorderView()
        self._addLineViews()
    }
    
    private func _addBorderView()
    {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.borderWidth = self._config.lineWidth
        
        self.addSubview(view)
        self._borderView = view
    }
    
    private func _addLineViews()
    {
        let formulas: [LineEntry.Formula] = [
            { s, d in s * 1 / 3 - d / 2 + 0.01 },
            { s, d in s * 1 / 3 + d / 2 + 0.01 },
            { s, d in s * 2 / 3 - d / 2 + 0.01 },
            { s, d in s * 2 / 3 + d / 2 + 0.01 },
        ]
        
        for axis in Axis.allCases {
            
            var lineEntries: [LineEntry] = []
            for (index, formula) in formulas.enumerated() {
                
                let view = UIView()
                view.isUserInteractionEnabled = false
                
                self.addSubview(view)
                lineEntries.append(.init(main: index % 2 == 0, formula: formula, view: view))
            }
            self._lineEntries[axis] = lineEntries
        }
    }
    
    private func _addGestureRecognizers(_ grs: [UIGestureRecognizer])
    {
        for gr in grs {
            gr.delegate = self
            self.addGestureRecognizer(gr)
        }
    }
    
    private func _syncScale()
    {
        let W = self.bounds.width
        let H = self.bounds.height
        
        guard W > 0, H > 0 else {
            self._scale = .init(1)
            return
        }
        
        self._scale = .init(
            self.coordinator.cropRect.frame.width  / W,
            self.coordinator.cropRect.frame.height / H
        )
    }
    
    // MARK: - Private Types
    
    private typealias Axis = KHAxisGeometry.Axis
    
    private struct LineEntry
    {
        let main: Bool
        let formula: Formula
        weak var view: UIView?
        
        typealias Formula = (_ s: CGFloat, _ d: CGFloat) -> CGFloat
    }
    
    // MARK: - System
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool 
    {
        guard let frame = self._delegate?.cropViewEventFrame(self) else {
            return super.point(inside: point, with: event)
        }
        
        return frame.contains(point)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension KHCropView_Delegate
{
    func cropViewWillBeginMoving(_ cropView: KHCropView) {}
    func cropViewDidFinishMoving(_ cropView: KHCropView) {}
    
    func cropViewWillBeginScaling(_ cropView: KHCropView) {}
    func cropViewDidFinishScaling(_ cropView: KHCropView) {}
    
    func cropViewEventFrame(_ cropView: KHCropView) -> CGRect? { nil }
}


// *************************
// *************************  Touches
// *************************

extension KHCropView
{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) 
    {
        self._decelerator.stop()
    }
}

// *************************
// *************************  Gestures
// *************************


extension KHCropView
{
    private func _stopPanning()
    {
        guard self._panning else {
            return
        }
        
        self._panGesture.isEnabled = false
        self._panGesture.isEnabled = true
    }
    
    private func _stopPinching()
    {
        guard self._pinching else {
            return
        }
        
        self._pinchGesture.isEnabled = false
        self._pinchGesture.isEnabled = true
    }
    
    private func _endPanning()
    {
        self._panning = false
        self._delegate?.cropViewDidFinishMoving(self)
    }
    
    @objc
    private func _didPan(_ recognizer: UIPanGestureRecognizer)
    {
        switch recognizer.state {
        case .began:
            self._delegate?.cropViewWillBeginMoving(self)
            self._decelerator.stop()
            self._panning = true
            self._syncScale()
        case .changed:
            let translation = recognizer.translation(in: self)
            if  self.coordinator.move(-translation * self._scale) {
                self._delegate?.cropViewDidUpdateCropRect(self)
            }
        case .ended:
            if  self._decelerator.start(with: recognizer.velocity(in: self)) {
                return
            }
            self._endPanning()
        case .cancelled:
            self._endPanning()
        default:
            break
        }
        
        recognizer.setTranslation(.zero, in: self)
    }

    @objc
    private func _didPinch(_ recognizer: UIPinchGestureRecognizer)
    {
        switch recognizer.state {
        case .began:
            self._delegate?.cropViewWillBeginScaling(self)
            self._decelerator.stop()
            self._pinching = true
        case .changed:
            var factor = Self._oppositeScale(recognizer.scale)
            let anchor = self.bounds.anchor(for: recognizer.location(in: self))
            if  self.coordinator.scale(&factor, anchor, allowsMoving: true) {
                self._scale = self._scale.scale(factor)
                self._delegate?.cropViewDidUpdateCropRect(self)
            }
        case .ended, .cancelled:
            self._pinching = false
            self._delegate?.cropViewDidFinishScaling(self)
        default:
            break
        }
        
        recognizer.scale = 1
    }
    
    private static func _oppositeScale(_ scale: CGFloat) -> CGFloat
    {
        return scale == 0 ? 1 : 1 / scale
    }
}


extension KHCropView: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return gestureRecognizer.delegate === self && otherGestureRecognizer.delegate === self
    }
}


// *************************
// *************************  Decelerator
// *************************


extension KHCropView: KHDecelerator_Delegate
{
    func deceleratorDidFinish(_ decelerator: KHDecelerator)
    {
        self._endPanning()
    }
    
    func decelerator(_ decelerator: KHDecelerator, didTickWith translation: CGPoint)
    {
        if  self.coordinator.move(-translation * self._scale) {
            self._delegate?.cropViewDidUpdateCropRect(self)
        } else {
            decelerator.stop()
        }
    }
}
