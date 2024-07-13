//
//  KHMainListView.swift
//  cropintegration
//
//  Created by Alex Khuala on 1.04.24.
//

import UIKit

enum KHMainListType: Equatable
{
    case crop
    case zoom
    case edit
}

class KHMainListContentProvider: KHListView_ContentProvider
{
    enum Mod: KHListView_Mod
    {
        case active
        
        var changes: KHListViewModChanges {
            switch self {
            case .active:       return [.colors]
            }
        }
    }
    
    var config: KHListViewConfig = .init { c in
        c.showsScrollIndicator = false
        c.allowsBounces = false
        c.clearance = KHPixel
    }
    
    var groups: [KHListView_Group] {
        return [
            KHMainListMainGroup(),
        ]
    }
}

fileprivate class KHMainListMainGroup: KHListView_Group
{
    var config: KHListViewGroupConfig = .init { c in

    }
    
    var rows: [KHListView_Row] {
        return [
            KHMainListRow(with: .crop, activeInitially: true),
            KHMainListRow(with: .zoom, activeInitially: true),
            KHMainListRow(with: .edit, activeInitially: true),
        ]
    }
}

// *************************
// *************************
// *************************

fileprivate class KHMainListRow: KHListView_Row
{
    let layoutID: String? = nil
    
    var config: KHListViewRowConfig = .init { c in
        c.minHeight = KHStyle.minListRowHeight
    }
        
    var cells: [KHListView_Cell] {
        
        let details = ActionDetails.details(for: self._action)
        let activeMod = KHMainListContentProvider.Mod.active
        
        var cells: [KHListView_Cell] = []
        cells.append(KHIndicatorListCell(with: details.checkbox ? .checkbox : .normal, activeMod: activeMod))
        cells.append(KHTitleListCell(with: details.title))

        return cells
    }
    
    let initialState: [any KHListView_Mod]
    let initiallyDisabled: Bool
    
    var associatedData: Any?
    {
        return self._action
    }
    
    init(with action: KHMainListType, activeInitially: Bool = false, disabledInitially: Bool = false)
    {
        self._action = action
        self.initialState = activeInitially ? [KHMainListContentProvider.Mod.active] : []
        self.initiallyDisabled = disabledInitially
    }
    
    func didChangeState(_ state: [any KHListView_Mod], adding: [any KHListView_Mod], removing: [any KHListView_Mod])
    {
        self._active = KHMainListContentProvider.Mod.active.isFound(in: state)
    }
    
    private var _action: KHMainListType
    private var _active: Bool = false
    
    struct ActionDetails
    {
        let title: String
        let checkbox: Bool
        
        init(_ title: String, checkbox: Bool = false)
        {
            self.title = title
            self.checkbox = checkbox
        }
        
        static func details(for action: KHMainListType) -> Self
        {
            switch action {
            case .crop:       return .init("Double tap the image or Tap the Crop button below to start editing", checkbox: true)
            case .zoom:       return .init("Zoom / Scroll the canvas to provide various positions for crop transition", checkbox: true)
            case .edit:       return .init("Please note that a higher resolution image is used during editing.", checkbox: true)
            }
        }
    }
}

