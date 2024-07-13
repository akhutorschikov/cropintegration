//
//  KHMainView_ViewModel.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

protocol KHMainView_ViewModel
{
    var contentSize: CGSize { get }
    
    var imageFrame: CGRect { get }
    var listFrame: CGRect { get }
    var imageSource: KHImageSource { get }
    var highResImageSource: KHImageSource { get }
    
    var cropRect: KHCropRect? { get }
    var orientation: KHOrientation2? { get }
    
    var listeners: KHMainView_Listeners { get }
}

protocol KHMainView_Listener: AnyObject
{
    func didRequestCrop()
}

protocol KHMainView_Listeners
{
    func add(_ listener: KHMainView_Listener)
    func remove(_ listener: KHMainView_Listener)
    func removeAll()
    func notify(in block: (_ listener: KHMainView_Listener) -> Void)
}
