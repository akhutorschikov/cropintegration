//
//  KHScrollSession.swift
//  cropintegration
//
//  Created by Alex Khuala on 23.12.23.
//

import Foundation

final class KHScrollSession
{
    func userStart() -> Bool
    {
        self._dragging = true
        
        if  self._active {
            return false
        }
        
        self._active = true
        return true
    }
    
    func userEnd()
    {
        self._dragging = false
    }
    
    @discardableResult
    func end() -> Bool
    {
        guard self._active, !self._dragging else {
            return false
        }
        
        self._active = false
        
        return true
    }
    
    var active: Bool {
        self._active
    }
    
    var decelerating: Bool {
        self._active && !self._dragging
    }
    
    private var _dragging: Bool = false
    private var _active: Bool = false
}
