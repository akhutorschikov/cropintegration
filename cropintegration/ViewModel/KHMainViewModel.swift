//
//  KHMainViewModel.swift
//  cropintegration
//
//  Created by Alex Khuala on 29.03.24.
//

import UIKit

class KHMainViewModel: KHMainView_ViewModel
{
    var contentSize: CGSize {
        KHContentManager.shared.canvasSize
    }
    
    var imageFrame: CGRect {
        KHContentManager.shared.imageFrame
    }
    
    var listFrame: CGRect {
        KHContentManager.shared.listFrame
    }
    
    var cropRect: KHCropRect? {
        KHContentManager.shared.cropRect
    }
    
    var orientation: KHOrientation2? {
        KHContentManager.shared.orientation
    }
    
    var imageSource: KHImageSource {
        .name("image-s.jpg")
    }
    
    var highResImageSource: KHImageSource {
        .name("image-xl.jpg")
    }
    
    let listeners: any KHMainView_Listeners = KHMainViewListeners()
}

fileprivate class KHMainViewListeners: KHMainView_Listeners
{
    typealias Listener = KHMainView_Listener
    
    func add(_ listener: Listener)
    {
        self._entries.append(.init(listener: listener))
    }
    
    func remove(_ listener: Listener)
    {
        self._entries.removeAll { $0.listener === listener }
    }
    
    func removeAll()
    {
        self._entries = []
    }
    
    func notify(in block: (_ listener: Listener) -> Void) {
        
        for entry in self._entries {
            guard let listener = entry.listener else {
                continue
            }
            block(listener)
        }
    }
    
    // MARK: - Private
    
    private var _entries: [Entry] = []
    private struct Entry
    {
        weak var listener: Listener?
    }
}
