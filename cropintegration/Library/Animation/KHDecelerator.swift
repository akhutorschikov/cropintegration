//
//  KHDecelerator.swift
//  kh-kit
//
//  Created by Alex Khuala on 28.08.23.
//

import UIKit

protocol KHDecelerator_Delegate: AnyObject
{
    func deceleratorDidFinish(_ decelerator: KHDecelerator)
    func decelerator(_ decelerator: KHDecelerator, didTickWith translation: CGPoint)
}

class KHDecelerator
{
    private(set) var decelerating: Bool = false
    
    init(delegate: KHDecelerator_Delegate, config: Config = .init())
    {
        self._config = config
        self._delegate = delegate
    }
    
    @discardableResult
    func start(with velocity: CGPoint) -> Bool
    {
        guard Self._strength(for: velocity) > self._config.minStrength else {
            return false
        }
        
        self.decelerating = true
        self._velocity = velocity
        
        let displaylink = CADisplayLink(target: self, selector: #selector(_decelerate))
        displaylink.add(to: .current, forMode: .default)
        displaylink.preferredFramesPerSecond = self._config.ticksPerSec
        
        self._timer = displaylink
        return true
    }
    
    func stop()
    {
        self._stop(notifying: false)
    }
    
    struct Config: KHConfig_Protocol
    {
        var minStrength: CGFloat = 600
        var attenuation: CGFloat = 0.97
        var endStrength: CGFloat = 20
        var coefficient: CGFloat = 0.01
        var ticksPerSec: Int = 60
    }
    
    // MARK: - Private
    
    private let _config: Config
    private var _velocity: CGPoint = .zero
    private var _timer: CADisplayLink?
    private weak var _delegate: KHDecelerator_Delegate?
    
    private func _stop(notifying: Bool)
    {
        self._timer?.invalidate()
        self._timer = nil
        self._velocity = .zero
        self.decelerating = false
        
        if  notifying {
            self._delegate?.deceleratorDidFinish(self)
        }
    }
    
    @objc
    private func _decelerate()
    {
        let velocity = self._velocity.scale(self._config.attenuation)
        let strength = Self._strength(for: velocity)

        guard strength > self._config.endStrength else {
            self._stop(notifying: true)
            return
        }
        
        self._velocity = velocity

        let delta = velocity.scale(self._config.coefficient)
        
        self._delegate?.decelerator(self, didTickWith: delta)
    }

    // MARK: - Class Private
    
    static private func _strength(for velocity: CGPoint) -> CGFloat
    {
        abs(velocity.x) + abs(velocity.y)
    }
}
