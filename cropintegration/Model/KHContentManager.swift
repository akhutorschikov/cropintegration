//
//  KHContentManager.swift
//  cropintegration
//
//  Created by Alex Khuala on 31.03.24.
//

import Foundation

final class KHContentManager
{
    // MARK: - Singleton
    
    public static let shared = KHContentManager()
    
    // MARK: - Init
    
    private init()
    {
    }

    // MARK: - Public
    
    let canvasSize: CGSize = .init(1200, 1600)
    let imageFrame: CGRect = .init(200, 250, 800, 500)
    let listFrame: CGRect = .init(200, 850, 800, 250)
    
    lazy var cropRect: KHCropRect? = self._loadCropRect()
    lazy var orientation: KHOrientation2? = .init()
    
    private func _loadCropRect() -> KHCropRect
    {
        .init(maxSize: .init(800, 500), angle: 0.424, frame: .init(143.2, 143.6, 443.8, 277.4))
    }
}
