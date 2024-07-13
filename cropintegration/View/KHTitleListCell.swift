//
//  KHTitleListCell.swift
//  cropintegration
//
//  Created by Alex Khuala on 6.04.23.
//

import UIKit

class KHTitleListCell: KHListView_Cell
{
    struct Config: KHConfig_Protocol
    {
        var padding: UIEdgeInsets = .zero
    }
    
    let minWidth: CGFloat = 50
    let stretchability: CGFloat = 1
            
    func createView() -> KHView
    {
        let view = KHTitleView(with: .init(in: { c in
            c.clearance = 2
            c.titleFont = KHStyle.listFont
            c.subtitleFont = KHStyle.listSmallFont
            c.padding = self._config.padding
        }))
        view.title = self._title
        view.subtitle = self._subtitle
        
        self._view = view
        
        return view
    }
    
    func updateColors(selected: Bool)
    {
        self._view?.titleColor = KHTheme.color.text

        if  self._view?.subtitle != nil {
            self._view?.subtitleColor = KHTheme.color.text
        }
    }
    
    init(with title: String, subtitle: String? = nil, config: Config = .init())
    {
        self._config = config
        self._title = title
        self._subtitle = subtitle
    }
    
    // MARK: - Private
    
    private var _config: Config
    
    private weak var _view: KHTitleView?
    private var _title: String
    private var _subtitle: String?
}
