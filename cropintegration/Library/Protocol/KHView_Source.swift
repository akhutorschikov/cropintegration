//
//  KHView_Source.swift
//  cropintegration
//
//  Created by Alex Khuala on 17.12.22.
//

import UIKit

/* IMPORTANT:
 
 DO NOT USE VIEW CLASS AS ITS OWN SOURCE
 USE KHViewSource INSTEAD
 
 */

protocol KHView_Source: KHView_Progressing
{
    var progress: CGFloat { get set } // optional
    
    func frame(in view: UIView?) -> CGRect
}

extension KHView_Source
{
    func view(target: UIView?, frameInView view: UIView?) -> CGRect
    {
        guard let vv = target else {
            return .zero
        }
        
        return vv.convert(vv.bounds, to: view)
    }
}

protocol KHView_Progressing
{
    var progress: CGFloat { get set } // optional
}

extension KHView_Progressing
{
    var progress: CGFloat { get { 0 } set {} }
}

protocol KHButton_Source: KHView_Source
{
    func deselect(animated: Bool)
    func reloadValue() // optional
    
    func select(animated: Bool) // optional
}

extension KHButton_Source
{
    func reloadValue() {}
    func select(animated: Bool) {}
}

struct KHViewSource: KHView_Source
{
    func frame(in view: UIView?) -> CGRect
    {
        return self.view(target: self._view, frameInView: view)
    }
    
    func presentationFrame(in view: UIView?) -> CGRect
    {
        guard let vv = self._view, let presentation = vv.layer.presentation() else {
            return .zero
        }
        
        return vv.superview!.convert(presentation.frame, to: view)
    }
    
    init(with view: UIView)
    {
        self._view = view
    }
    
    private weak var _view: UIView?
}


struct KHEmptyButtonSource: KHButton_Source
{
    func deselect(animated: Bool) {}
    
    func frame(in view: UIView?) -> CGRect
    {
        return self.view(target: self._view, frameInView: view)
    }
    
    init(_ view: UIView?)
    {
        self._view = view
    }
    
    private weak var _view: UIView?
}
