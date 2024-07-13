//
//  KHAnimationBox.swift
//  cropintegration
//
//  Created by Alex Khuala on 7.09.23.
//

final class KHAnimationBox
{
    let registry: Registry
    
    init()
    {
        self.registry = .init()
    }
    
    func hasAnimations() -> Bool
    {
        self.registry.hasAnimations()
    }
    
    func hasCompletions() -> Bool
    {
        self.registry.hasCompletions()
    }
    
    func executeAnimations(reset: Bool)
    {
        self.registry.executeAnimations(reset: reset)
    }
    
    func executeCompletions(reset: Bool)
    {
        self.registry.executeCompletions(reset: reset)
    }
    
    func openRegistry()
    {
        self.registry.closed = false
    }
    
    final class Registry
    {
        fileprivate(set) var closed: Bool = false
        
        fileprivate init()
        {
        }
        
        func addAnimation(_ animation: @escaping Animation)
        {
            guard !self.closed else {
                return
            }
            self._animations.append(animation)
        }
        
        func addCompletion(_ completion: @escaping Completion)
        {
            guard !self.closed else {
                return
            }
            self._completions.append(completion)
        }
        
        fileprivate func hasAnimations() -> Bool
        {
            !self._animations.isEmpty
        }
        
        fileprivate func hasCompletions() -> Bool
        {
            !self._completions.isEmpty
        }
        
        fileprivate func executeAnimations(reset: Bool)
        {
            self.closed = true
            
            for animation in self._animations {
                animation()
            }
            if  reset {
                self._animations.removeAll()
            }
        }
        
        fileprivate func executeCompletions(reset: Bool)
        {
            self.closed = true
            
            for completion in self._completions {
                completion()
            }
            if  reset {
                self._completions.removeAll()
            }
        }
        
        private var _animations: [Animation] = []
        private var _completions: [Completion] = []
    }
    
    typealias Animation = () -> Void
    typealias Completion = () -> Void
}
