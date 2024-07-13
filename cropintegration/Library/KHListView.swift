//
//  KHListView.swift
//  kh-kit
//
//  Created by Alex Khuala on 22.12.22.
//

import UIKit

protocol KHListView_Mod: Equatable, CaseIterable
{
    var changes: KHListViewModChanges { get }
}

struct KHListViewModChanges: OptionSet
{
    let rawValue: Int
    
    static let config = Self(rawValue: 1 << 0)
    static let layout = Self(rawValue: 1 << 1)
    static let colors = Self(rawValue: 1 << 2)
}

protocol KHListView_StateSensitive: AnyObject
{
    func didChangeState(_ state: [any KHListView_Mod], adding: [any KHListView_Mod], removing: [any KHListView_Mod]) // optional
}

protocol KHListView_ContentProvider: KHListView_StateSensitive
{
    associatedtype Mod: KHListView_Mod
    
    var config: KHListViewConfig { get }
    var groups: [any KHListView_Group] { get }
 
    var backgroundColor: UIColor? { get } // optional
    var borderColor: UIColor? { get } // optional
    
    func createHeaderView() -> KHListView_OpenView? // optional
    func createFooterView() -> KHListView_OpenView? // optional
}

protocol KHListView_OpenDelegate: AnyObject
{
    func openView(_ view: KHListView_OpenView, didRequestOpen: Bool, animated: Bool)
}

protocol KHListView_OpenView: KHView
{
    func updateOpenProgress(_ openProgress: CGFloat, scrolling: Bool)
    
    /*!
     To make openDelegate work save it as weak and return true
     */
    func registerOpenDelegate(_ openDelegate: KHListView_OpenDelegate) -> Bool
    
    var minHeight: CGFloat { get }
    var maxHeight: CGFloat { get }
}

protocol KHListView_Group: KHListView_StateSensitive
{
    var config: KHListViewGroupConfig { get }
    var rows: [any KHListView_Row] { get }
    
    func createHeaderView() -> KHView? // optional
    func createFooterView() -> KHView? // optional
    
    var backgroundColor: UIColor? { get } // optional
    var borderColor: UIColor? { get } // optional
    var separatorColor: UIColor? { get } // optional
    var lastSeparatorColor: UIColor? { get } // optional
    var selectedSeparatorColor: UIColor? { get } // optional
}

protocol KHListView_Row: KHListView_StateSensitive
{
    var layoutID: String? { get } // optional
    
    var config: KHListViewRowConfig { get }
    var cells: [any KHListView_Cell] { get }
    var initialState: [any KHListView_Mod] { get } // optional
    var initiallyDisabled: Bool { get } // optional
    var associatedData: Any? { get } // optional
    
    var backgroundColor: UIColor? { get } // optional
    var borderColor: UIColor? { get } // optional
    var selectedBackgroundColor: UIColor? { get } // optional
    var selectedBorderColor: UIColor { get } // optional
}

protocol KHListView_Cell: KHListView_StateSensitive
{
    var stretchability: CGFloat { get } // optional, default 0
    var minWidth: CGFloat { get }
    var visible: Bool { get } // optional, default true
    
    func createView() -> KHView
    
    // Called once after initialization so no need to set color twice
    func updateColors(selected: Bool) // optional
}

protocol KHListView_Delegate: AnyObject
{
    func listViewDidSelectRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?)
    func listViewDidToggleRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?) // optional
    func listViewWillBeginScrolling() // optional
    func listViewDidFinishScrolling() // optional
}

extension KHListView_Delegate
{
    func listViewDidToggleRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?) 
    {
        self.listViewDidSelectRow(a, at: indexPath, associatedData: associatedData)
    }
    
    func listViewWillBeginScrolling() {}
    func listViewDidFinishScrolling() {}
}

// ******** CONFIG ******** //

struct KHListViewConfig: KHConfig_Protocol
{
    var padding: UIEdgeInsets = .zero
    var clearance: CGFloat = 0 // clearance between groups
    var showsScrollIndicator: Bool = true
    var allowsBounces: Bool = true
    var borderWidth: CGFloat = 0
}

struct KHListViewGroupConfig: KHConfig_Protocol
{
    var selectionAnimationDuration: TimeInterval = 0.25
    
    var clearance: CGFloat = 0 // clearance between rows
    var borderWidth: CGFloat = 0
    var cornerRadius: CGFloat = 0
    var separatorConfig: KHSeparatorConfig?
    var lastSeparatorConfig: KHSeparatorConfig?
    var firstRowTopPadding: CGFloat = 0
    var lastRowBottomPadding: CGFloat = 0
    
    fileprivate func needsSeparator(last: Bool) -> Bool
    {
        guard last else {
            return self.separatorConfig != nil
        }
        return self.lastSeparatorConfig != nil
    }
}

struct KHListViewRowConfig: KHConfig_Protocol
{
    var clearance: CGFloat = 0 // clearance between cells
    var minHeight: CGFloat = 44
    var cornerRadius: CGFloat = 0
    var borderWidth: CGFloat = 0
    var selectedBorderWidth: CGFloat = 0
}

struct KHListViewActionAdapter: KHButton_Source
{
    func deselect(animated: Bool = false)
    {
        self.rowView?.setSelected(false, animated: animated)
    }
    
    func reloadValue()
    {
        // TODO: repopulate row view and layout entire list
    }
    
    func frame(in view: UIView?) -> CGRect
    {
        return self.view(target: self.rowView, frameInView: view)
    }
    
    fileprivate init(rowView: KHControl)
    {
        self.rowView = rowView
    }
    
    private weak var rowView: KHControl?
}

struct KHListViewIndexPath: Equatable
{
    private(set) var group: Int
    private(set) var row: Int?
    
    init(group: Int, row: Int? = nil)
    {
        self.group = group
        self.row = row
    }
}

// *************

final class KHListView<ContentProvider: KHListView_ContentProvider>: KHView, KHColor_Sensitive, UIScrollViewDelegate
{
    
    /*!
     @discussion Use only when it needs to reload all colors of the list
                 If it needs to reload colors of one gruop or row use mod methods and configure .colors changes
     */
    
    func updateColors()
    {
        self._setColors()
        self._entries.forEach { $0.groupView?.updateColors() }
        KHColorSensitiveTools.updateColors(of: self._headerView)
        KHColorSensitiveTools.updateColors(of: self._footerView)
    }
    
    /*!
     @brief Change state of list and its parts
     @discussion When IndexPath = nil - applied to all table
                 When IndexPath = single index - applied to full group
                 When IndexPath = 2 indexes - applied to specific row
     */
    
    struct StateAdapter
    {
        func appendMod(_ mod: ContentProvider.Mod, at indexPath: KHListViewIndexPath? = nil)
        {
            self.appendMods([mod], at: indexPath)
        }
        func appendMods(_ mods: [ContentProvider.Mod], at indexPath: KHListViewIndexPath? = nil)
        {
            self._parent?._appendMods(KHListViewState.convertToStatic(mods: mods), at: indexPath)
        }
        func removeMod(_ mod: ContentProvider.Mod, at indexPath: KHListViewIndexPath? = nil)
        {
            self.removeMods([mod], at: indexPath)
        }
        func removeMods(_ mods: [ContentProvider.Mod], at indexPath: KHListViewIndexPath? = nil)
        {
            self._parent?._removeMods(KHListViewState.convertToStatic(mods: mods), at: indexPath)
        }
        func removeAllMods(at indexPath: KHListViewIndexPath? = nil)
        {
            self._parent?._removeAllMods(at: indexPath)
        }
        
        fileprivate init(with parent: KHListView)
        {
            self._parent = parent
        }
        
        private weak var _parent: KHListView?
    }
    
    private var _stateRegistry: [ViewState] = []
    
    func changeState(in block: (_ a: StateAdapter) -> Void)
    {
        let adapter = StateAdapter(with: self)
        
        // execute block with changes: add, remove, removeAll
        block(adapter)
        
        var changes: KHListViewModChanges = []
        for viewState in self._stateRegistry {
            if viewState.commitChanges() {
                changes.insert(viewState.lastChanges)
            }
        }
        
        // reset registry
        self._stateRegistry = []
        
        if  changes.contains(.layout) {
            self.setNeedsLayout()
            
            let animationDuration = UIView.inheritedAnimationDuration
            if (animationDuration > 0) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func reloadListData()
    {
        self._clearListViews()
        self._addGroupViews(updateColors: true)
        self._bringOpenViewsToFront()
        self.setNeedsLayout()
    }
    
    // MARK: - Init
    
    init(with contentProvider: ContentProvider, mods: [ContentProvider.Mod] = [], delegate: KHListView_Delegate? = nil)
    {
        self._state = KHListViewState(with: mods)
        self._state.notify(contentProvider)
        
        self._config = contentProvider.config
        self._contentProvider = contentProvider
        self._delegate = delegate
        
        super.init(frame: .standard)
        
        self._state.parent = self
     
        self._addScrollView()
        self._configure()
        self._setColors()
        self._populate()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: LayoutOptions)
    {
        guard let scrollView = self._scrollView else {
            return
        }
        
        self._scrollHandlerDisabled = true
        defer { self._scrollHandlerDisabled = false }
        
        // ------ Header view
        
        var headerMargin: CGFloat = 0
        if  let view = self._headerView {
            let inside = scrollView.contentOffset.y < (view.maxHeight - view.minHeight) + 0.01
            
            view.width = self.bounds.width
            view.forceLayout(options: .sizeToFitHeight)
            
            let maxHeight = view.maxHeight
            
            view.top = maxHeight - view.height
            scrollView.contentInset.top = -view.top
            if  inside {
                scrollView.contentOffset.y = view.top
            }

            headerMargin = maxHeight
        }

        // ------ Group views
        
        let padding = self._config.padding.expand(to: contentInset)
        
        // clearing top inset to calculate frame pos more easily
        let bounds = self.bounds.inset(padding.top(0))
        let clearance = self._config.clearance
        
        var contentHeight: CGFloat = 0
        var top: CGFloat = padding.top + headerMargin
        for entry in self._entries {
        
            if let view = entry.groupView {
                
                view.frame = bounds.inframe(.init(height: 80), .top, .init(top: top)).pixelRound()
                view.forceLayout(options: .sizeToFitHeight)
                
                contentHeight = view.bottom
                top = contentHeight + clearance
            }
        }
        
        // ------ Footer view Part-1
        
        var footerMargin: CGFloat = 0
        if  let view = self._footerView {
            
            view.width = self.bounds.width
            view.forceLayout(options: .sizeToFitHeight)
            
            footerMargin = view.maxHeight
        }
        
        // ------ Sync scroll size
        
        scrollView.contentSize = self.bounds.size.height(contentHeight + footerMargin + padding.bottom)
        if  options.contains(.sizeToFitHeight) {
            self.height = scrollView.contentSize.height
        }
        scrollView.frame = self.bounds
        
        // ------ Footer view Part-2
        
        if  let view = self._footerView {
            
            let maxHeight = footerMargin
            let minOffset = view.height - view.minHeight - scrollView.contentInset.top
            
            // update content size
            
            if  scrollView.contentOffset.y < minOffset {
                scrollView.contentOffset.y = minOffset
            }
            scrollView.contentInset.bottom = view.height - maxHeight
            
            self._updateFooterPosition(for: scrollView)
        }
    }
    
    // MARK: - Private
    
    private struct GroupEntry
    {
        weak var groupView: KHListGroupView<ContentProvider.Mod>?
    }
    
    private var _config: KHListViewConfig
    private var _contentProvider: ContentProvider
    private weak var _delegate: KHListView_Delegate?
    private var _state: KHListViewState<ContentProvider.Mod>
    private var _entries: [GroupEntry] = []
    
    private weak var _scrollView: UIScrollView?
    private weak var _headerView: KHListView_OpenView?
    private weak var _footerView: KHListView_OpenView?
    
    private func _addScrollView()
    {
        let view = UIScrollView(.standard)
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.delegate = self
        view.contentInsetAdjustmentBehavior = .never
        
        self._scrollView = view
        self.addSubview(view)
    }
    
    private func _configure()
    {
        if  let view = self._scrollView {
            view.showsVerticalScrollIndicator = self._config.showsScrollIndicator
            view.bounces = self._config.allowsBounces
        }
        self.layer.borderWidth = self._config.borderWidth
    }
    
    private func _setColors()
    {
        self.backgroundColor = self._contentProvider.backgroundColor
        if  self._config.borderWidth > 0 {
            self.layer.borderColor = self._contentProvider.borderColor?.cgColor
        }
    }
    
    private func _populate()
    {
        self._addGroupViews()
        self._addHeaderView()
        self._addFooterView()
    }
    
    private func _addGroupViews(updateColors: Bool = false)
    {
        guard let scrollView = self._scrollView else {
            return
        }
        
        let mods = self._state.currentState
        let groups = self._contentProvider.groups
        for i in 0..<groups.count {
            let view = KHListGroupView(with: i, group: groups[i], delegate: self, mods: mods)
            
            if  updateColors {
                view.updateColors()
            }
            
            scrollView.addSubview(view)
            self._entries.append(GroupEntry(groupView: view))
        }
    }
    
    private func _addHeaderView()
    {
        guard let view = self._contentProvider.createHeaderView() else {
            return
        }
        
        self._scrollView?.addSubview(view)
        self._headerView = view
        
        self._needsUpdateHeaderOpenState = view.registerOpenDelegate(self)
    }
    
    private func _addFooterView()
    {
        guard let view = self._contentProvider.createFooterView() else {
            return
        }
        
        self._scrollView?.addSubview(view)
        self._footerView = view
        
        self._needsUpdateFooterOpenState = view.registerOpenDelegate(self)
    }
    
    private func _bringOpenViewsToFront()
    {
        guard let scrollView = self._scrollView else {
            return
        }
        
        if  let view = self._headerView {
            scrollView.bringSubviewToFront(view)
        }
        if  let view = self._footerView {
            scrollView.bringSubviewToFront(view)
        }
    }
    
    private func _clearListViews()
    {
        self._entries.forEach { $0.groupView?.removeFromSuperview() }
        self._entries = []
    }
        
    fileprivate typealias ViewState = KHListViewState<ContentProvider.Mod>
    
    private func _changeMods(at indexPath: KHListViewIndexPath?, in block: () -> Void, and groupBlock: (_ groupView: KHListGroupView<ContentProvider.Mod>, _ rowIndex: Int?, _ registry: inout [ViewState]) -> Void)
    {
        if let indexPath = indexPath {
            
            let i = indexPath.group
            if  i < self._entries.count, let groupView = self._entries[i].groupView {
                groupBlock(groupView, indexPath.row, &self._stateRegistry)
            }
            
        } else {
            
            // self
            
            ViewState.registerStateForChanges(self._state, in: &self._stateRegistry)
            block()
            
            // children
            
            for entry in self._entries {
                guard let groupView = entry.groupView else {
                    continue
                }
                groupBlock(groupView, nil, &self._stateRegistry)
            }
        }
    }
    
    fileprivate func _appendMods(_ mods: [KHListViewState<ContentProvider.Mod>.StaticMod], at indexPath: KHListViewIndexPath?)
    {
        self._changeMods(at: indexPath) {
            self._state.add(mods)
        } and: { groupView, rowIndex, registry in
            groupView.appendMods(mods, at: rowIndex, with: &registry)
        }
    }
    
    fileprivate func _removeMods(_ mods: [KHListViewState<ContentProvider.Mod>.StaticMod], at indexPath: KHListViewIndexPath?)
    {
        self._changeMods(at: indexPath) {
            self._state.remove(mods)
        } and: { groupView, rowIndex, registry in
            groupView.removeMods(mods, at: rowIndex, with: &registry)
        }
    }
    
    fileprivate func _removeAllMods(at indexPath: KHListViewIndexPath?)
    {
        self._changeMods(at: indexPath) {
            self._state.removeAllMods()
        } and: { groupView, rowIndex, registry in
            groupView.removeAllMods(at: rowIndex, with: &registry)
        }
    }
    
    // MARK: - Scrolling
    
    private var _scrolling: KHScrollSession = .init()
    private var _scrollHandlerDisabled: Bool = false
    
    private var _needsUpdateHeaderOpenState: Bool = false
    private var _needsUpdateFooterOpenState: Bool = false
    
    private func _openProgress(for view: KHListView_OpenView, newHeight: CGFloat) -> CGFloat
    {
        let newDelta = newHeight - view.minHeight
        let distance = view.maxHeight - view.minHeight
        var progress: CGFloat = 0
        if  newDelta > 0, distance > 0 {
            progress = newDelta / distance
        }
        return progress
    }
    
    private func _pushSize(for view: KHListView_OpenView, delta: CGFloat, final: Bool, completion: @escaping (_ changed: Bool) -> Void)
    {
        guard delta > 0 || (final && view.height < view.maxHeight), view.height > view.minHeight else {
            
            if  final {
                let progress = self._openProgress(for: view, newHeight: view.height)
                view.updateOpenProgress(progress, scrolling: self._scrolling.active)
            }
            
            completion(false)
            return
        }
        
        var newHeight = max(view.height - delta, view.minHeight)
        var progress = self._openProgress(for: view, newHeight: newHeight)
        
        guard final else {
            view.layer.removeAllAnimations()
            view.updateOpenProgress(progress, scrolling: self._scrolling.active)
            view.height = newHeight
            view.layoutIfNeeded()
            completion(true)
            return
        }
        
        let distanceMin = newHeight - view.minHeight
        let distanceMax = view.maxHeight - newHeight
        let open = distanceMax < distanceMin
        
        if  open {
            progress = 1
            newHeight = view.maxHeight
        } else {
            progress = 0
            newHeight = view.minHeight
        }
        
        UIView.animate(withDuration: KHViewHelper.animationDuration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut]) { [weak view] in
            guard let view = view else {
                return
            }
            view.updateOpenProgress(progress, scrolling: self._scrolling.active)
            view.height = newHeight
            view.layoutIfNeeded()
            completion(true)
        }
    }
    
    private func _updateHeaderOpenState(for scrollView: UIScrollView, final: Bool)
    {
        guard self._needsUpdateHeaderOpenState, let view = self._headerView else {
            return
        }
        
        let delta = scrollView.contentOffset.y + scrollView.contentInset.top
        
        self._pushSize(for: view, delta: delta, final: final) { [weak view, weak self] changed in
            guard changed, let self = self, let view = view else {
                return
            }
            self._updateScrollViewForOpenHeaderView(view, needsSyncOffset: final)
//            self._updateOpenViewPosition(for: view, needsSyncOffset: final)
        }
    }
    
    private func _updateFooterOpenState(for scrollView: UIScrollView, final: Bool)
    {
        guard self._needsUpdateFooterOpenState, let view = self._footerView else {
            return
        }
        
        let delta = view.bottom - (scrollView.contentOffset.y + scrollView.height)
        
        self._pushSize(for: view, delta: delta, final: final) { [weak view, weak self] changed in
            guard let self = self, let view = view else {
                return
            }
            self._updateScrollViewForOpenFooterView(view, needsSyncOffset: final)
//            self._updateOpenViewPosition(for: view, needsSyncOffset: final)
        }
    }
    
    private func _updateFooterPosition(for scrollView: UIScrollView)
    {
        guard let view = self._footerView else {
            return
        }
        
        let offset = scrollView.contentOffset.y
        
        let minBottom = max(-scrollView.contentInset.top, offset) + scrollView.height
        let maxBottom = scrollView.contentSize.height + scrollView.contentInset.bottom
        
        view.top = min(minBottom, maxBottom) - view.height
    }
    
    private func _updateScrollViewForOpenFooterView(_ view: KHListView_OpenView, needsSyncOffset: Bool = false) 
    {
        guard let scrollView = self._scrollView, view === self._footerView else {
            return
        }
        
        self._scrollHandlerDisabled = true
        defer { self._scrollHandlerDisabled = false }
        
        let bottom = view.height - view.maxHeight
        if  bottom != scrollView.contentInset.bottom {
            let delta = bottom - scrollView.contentInset.bottom
            if  needsSyncOffset {
                scrollView.contentOffset.y += delta
            }
            scrollView.contentInset.bottom = bottom
        }
        
        self._updateFooterPosition(for: scrollView)
    }
    
    private func _updateScrollViewForOpenHeaderView(_ view: KHListView_OpenView, needsSyncOffset: Bool = false)
    {
        guard let scrollView = self._scrollView, view === self._headerView else {
            return
        }
        
        self._scrollHandlerDisabled = true
        defer { self._scrollHandlerDisabled = false }
        
        let top  = view.maxHeight - view.height
        if  top != view.top {
            scrollView.contentInset.top = -top
            view.top = top
        }
        if  needsSyncOffset {
            scrollView.contentOffset.y = view.top
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        guard self._scrolling.userStart() else {
            return
        }

        self._delegate?.listViewWillBeginScrolling()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        guard !self._scrollHandlerDisabled else {
            return
        }
        
        self._scrollHandlerDisabled = true
        defer { self._scrollHandlerDisabled = false }
        
        self._updateHeaderOpenState(for: scrollView, final: false)
        self._updateFooterOpenState(for: scrollView, final: false)
                
//        guard self._scrolling.active else {
//            return
//        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        self._scrolling.userEnd()
        guard !decelerate else {
            return
        }
        self._endScrolling(scrollView: scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        self._endScrolling(scrollView: scrollView)
    }
    
    private func _endScrolling(scrollView: UIScrollView)
    {
        guard self._scrolling.end() else {
            return
        }
        self._scrollHandlerDisabled = true
        defer { self._scrollHandlerDisabled = false }
        
        self._updateHeaderOpenState(for: scrollView, final: true)
        self._updateFooterOpenState(for: scrollView, final: true)
        
        // ------
     
        self._delegate?.listViewDidFinishScrolling()
    }
}

extension KHListView: KHListView_OpenDelegate
{
    func openView(_ view: KHListView_OpenView, didRequestOpen open: Bool, animated: Bool)
    {
        let progress: CGFloat
        let newHeight: CGFloat
        if  open {
            progress = 1
            newHeight = view.maxHeight
        } else {
            progress = 0
            newHeight = view.minHeight
        }
        
        guard animated else {
            view.updateOpenProgress(progress, scrolling: self._scrolling.active)
            view.height = newHeight
            return
        }
        
        UIView.animate(withDuration: KHViewHelper.animationDuration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut]) { [weak view, weak self] in
            guard let self = self, let view = view else {
                return
            }
            view.updateOpenProgress(progress, scrolling: self._scrolling.active)
            view.height = newHeight
            view.layoutIfNeeded()
            
            self._updateScrollViewForOpenHeaderView(view, needsSyncOffset: true)
            self._updateScrollViewForOpenFooterView(view, needsSyncOffset: true)
        }
    }
}

extension KHListView: KHListViewState_Delegate
{
    fileprivate func commitChanges(_ changes: KHListViewModChanges)
    {
        self._state.notify(self._contentProvider)
        
        if  changes.contains(.config) {
            self._config = self._contentProvider.config
            self._configure()
        }
        
        if  changes.contains(.colors) {
            self._setColors()
        }
    }
}

extension KHListView: KHListGroupView_Delegate
{
    func listViewDidSelectRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?)
    {
        if  let delegate = self._delegate {
            DispatchQueue.main.async {
                delegate.listViewDidSelectRow(a, at: indexPath, associatedData: associatedData)
            }
        } else {
            a.deselect(animated: true)
        }
    }
    
    func listViewDidToggleRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?)
    {
        if  let delegate = self._delegate {
            DispatchQueue.main.async {
                delegate.listViewDidToggleRow(a, at: indexPath, associatedData: associatedData)
            }
        } else {
            a.deselect(animated: true)
        }
    }
}

private protocol KHListGroupView_Delegate: AnyObject
{
    func listViewDidSelectRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?)
    func listViewDidToggleRow(_ a: KHListViewActionAdapter, at indexPath: KHListViewIndexPath, associatedData: Any?)
}

private class KHListGroupView<Mod: KHListView_Mod>: KHView
{
    private(set) var index: Int
    private(set) var group: KHListView_Group
    
    typealias ViewState = KHListViewState<Mod>
    typealias StaticMod = ViewState.StaticMod
    
    func updateColors()
    {
        // TODO: update header and footer view colors
        
        self._setColors()
        self._setSeparatorsColor()
        
        for entry in self._entries {
            entry.view?.updateColors()
        }
    }
    
    func appendMods(_ mods: [StaticMod], at rowIndex: Int?, with registry: inout [ViewState])
    {
        self._changeMods(at: rowIndex, with: &registry) {
            self._state.add(mods)
        } and: { rowView, registry in
            rowView.appendMods(mods, with: &registry)
        }
    }
    
    func removeMods(_ mods: [StaticMod], at rowIndex: Int?, with registry: inout [ViewState])
    {
        self._changeMods(at: rowIndex, with: &registry) {
            self._state.remove(mods)
        } and: { rowView, registry in
            rowView.removeMods(mods, with: &registry)
        }
    }
    
    func removeAllMods(at rowIndex: Int?, with registry: inout [ViewState])
    {
        self._changeMods(at: rowIndex, with: &registry) {
            self._state.removeAllMods()
        } and: { rowView, registry in
            rowView.removeAllMods(with: &registry)
        }
    }
    
    init(with index: Int, group: KHListView_Group, delegate: KHListGroupView_Delegate?, mods: [StaticMod])
    {
        self._state = KHListViewState(with: mods)
        self._state.notify(group)
        
        let config = group.config
        
        self.index = index
        self.group = group
        
        self._delegate = delegate
        
        // load config after state is changed
        self._config = config
        
        super.init(frame: .standard)
        
        self._state.parent = self
        
        self._addContentView()
        self._configure()
        self._setColors()
        self._populate()
        self._setSeparatorsColor()
        self._updateLastSeparatorVisibility()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: LayoutOptions)
    {
        guard let contentView = self._contentView else {
            return
        }
        
        let config = self._config
        let bounds = self.bounds.inset(contentInset)
        
        // @TODO: layout header view
        
        // layout content view
        
        contentView.frame = bounds
        
        let clearance = config.clearance
        let separatorConfig = config.separatorConfig ?? .zero
        let lastSeparatorConfig = config.lastSeparatorConfig
        
        let contentBounds = contentView.bounds
        var contentHeight: CGFloat = 0
        var top: CGFloat = 0
        
        var layoutItems: [LayoutItem] = []
        
        // #1: Collect layout schemes
        var layoutSchemes: [String: [CGFloat]] = [:]
        for entry in self._entries {
            
            var layoutItem = LayoutItem(entry: entry)
            
            // layout row view
            if let view = entry.view {
                
                let padding = view.padding
                let height = padding.top + padding.bottom + view.row.config.minHeight
                
                view.size = KHSize(contentBounds.width, height).pixelRound()
                if let layoutID = view.row.layoutID {
                    layoutSchemes[layoutID] = view.createLayoutScheme(with: layoutSchemes[layoutID])
                    layoutItem.layoutID = layoutID
                }
            }
            
            layoutItems.append(layoutItem)
        }
        
        // #2: Layout with or without scheme
        let lastIndex = layoutItems.count - 1
        for (index, layoutItem) in layoutItems.enumerated() {
            
            let entry = layoutItem.entry
            
            // layout row view
            if  let view = entry.view {
                view.frame = contentBounds.inframe(view.size, .top, .init(top: top)).pixelRound()
                
                if let layoutID = layoutItem.layoutID {
                    view.layoutScheme = layoutSchemes[layoutID]
                }
                
                view.forceLayout()
                
                contentHeight = view.bottom
                top = contentHeight + clearance
            }
            
            // layout separator
            if  let separatorView = entry.nextSeparatorView {
                
                let config: KHSeparatorConfig
                if  index == lastIndex {
                    config = lastSeparatorConfig ?? separatorConfig
                } else {
                    config = separatorConfig
                }
                
                let inset = config.inset + .init(top:max(0, (clearance - config.lineWidth) / 2) + (entry.view?.bottom ?? 0))
                
                let frame = contentBounds.inframe(.init(height: config.lineWidth), .top, inset)
                
                separatorView.frame = frame.pixelRoundPosition()
            }
        }
        
        // update height
        contentView.height = contentHeight
        
        // update corner radius if required
        KHViewHelper.setCornerRadius(self._config.cornerRadius, to: contentView)
        
        self.height = contentView.bottom + contentInset.bottom
    }
    
    // MARK: - Internal
    
    private var _state: KHListViewState<Mod>
    private var _config: KHListViewGroupConfig
    private weak var _delegate: KHListGroupView_Delegate?
    private var _entries: [RowEntry] = []
    
    private weak var _contentView: KHView?
    
    private func _addContentView()
    {
        let view = KHView(.standard)
        
        self.addSubview(view)
        self._contentView = view
    }
    
    private func _configure()
    {
        guard let view = self._contentView else {
            return
        }
        
        let config = self._config
        if  config.cornerRadius > 0 {
            KHViewHelper.setCornerRadius(config.cornerRadius, to: view)
            view.clipsToBounds = true
        } else {
            view.clipsToBounds = false
        }
        if  config.borderWidth > 0 {
            view.layer.borderWidth = config.borderWidth
        }
    }
    
    private func _setColors()
    {
        guard let view = self._contentView else {
            return
        }
        
        let group = self.group
        let config = self._config
        
        view.backgroundColor = group.backgroundColor
        if  config.borderWidth > 0 {
            view.layer.borderColor = (group.borderColor ?? .gray).cgColor
        }
    }
    
    private func _setSeparatorsColor()
    {
        if  self._config.separatorConfig != nil {
            let color = self.group.separatorColor
            
            // all separators including last
            
            let lastIndex = self._entries.count - 1
            for (index, entry) in self._entries.enumerated() {
                
                if  index == lastIndex {
                    if  let view = entry.nextSeparatorView {
                        view.backgroundColor = self.group.lastSeparatorColor ?? color
                    }
                } else {
                    entry.nextSeparatorView?.backgroundColor = color
                }
            }
            
        } else if self._config.lastSeparatorConfig != nil, let entry = self._entries.last, let view = entry.nextSeparatorView {
            
            // only last separator
            
            view.backgroundColor = self.group.lastSeparatorColor ?? self.group.separatorColor
        }
    }
    
    private class SeparatorView: KHView
    {
        var selected: Bool {
            return self._prevSelected || self._nextSelected
        }
        
        // return true when this action is changed separator view selected state
        @discardableResult
        func setPrevRowSelected(_ selected: Bool) -> Bool
        {
            let oldSelected = self.selected
            
            self._prevSelected = selected
            
            return oldSelected != self.selected
        }
        
        // return true when this action is changed separator view selected state
        @discardableResult
        func setNextRowSelected(_ selected: Bool) -> Bool
        {
            let oldSelected = self.selected
            
            self._nextSelected = selected
            
            return oldSelected != self.selected
        }
        
        // MARK: - Private
        
        private var _prevSelected: Bool = false
        private var _nextSelected: Bool = false
    }
    
    private struct RowEntry
    {
        weak var view: KHListRowView<Mod>?
        weak var prevSeparatorView: SeparatorView?
        weak var nextSeparatorView: SeparatorView?
    }
    
    private struct LayoutItem
    {
        var entry: RowEntry
        var layoutID: String?
    }
    
    private func _populate()
    {
        guard let contentView = self._contentView else {
            return
        }
        
        let rows = self.group.rows
        guard rows.count > 0 else {
            return
        }
        
        let mods = self._state.currentState
        let config = self._config
        var entries: [RowEntry] = []
        var prevSeparatorView: SeparatorView?
        
        var tmpSeparatorViews: [SeparatorView] = []
        
        let lastIndex = rows.count - 1
        
        for (i, row) in rows.enumerated() {
            
            let first = i == 0
            let last = i == lastIndex
            
            var entry = RowEntry()
            entry.prevSeparatorView = prevSeparatorView
            
            var rowMods = mods
            
            if  let initialMods = row.initialState as? [Mod], initialMods.count > 0 {
                rowMods += KHListViewState.convertToStatic(mods: initialMods)
            }
            
            let view = KHListRowView(with: i, row: rows[i], delegate: self, mods: rowMods)
            view.animationDuration = config.selectionAnimationDuration
            view.enabled = !row.initiallyDisabled
            if  first { // first
                view.padding.top += self._config.firstRowTopPadding
            }
            if  last { // last
                view.padding.bottom += self._config.lastRowBottomPadding
            }
            
            contentView.addSubview(view)
            entry.view = view
            
            // ------ create separator view and append to tmp array
            
            if  config.needsSeparator(last: last) {
                let separatorView = SeparatorView(.line)
                
                entry.nextSeparatorView = separatorView
                
                tmpSeparatorViews.append(separatorView)
                prevSeparatorView = separatorView
            }
            
            entries.append(entry)
        }
        
        // add separator views to content view to make them all above row views
        for separatorView in tmpSeparatorViews {
            contentView.addSubview(separatorView)
        }
        
        self._entries = entries
    }
    
    private func _updateLastSeparatorVisibility()
    {
//        self._entries.last?.nextSeparatorView?.isHidden = !self._config.separatorLastVisible
    }
    
    private func _changeMods(at rowIndex: Int?, with registry: inout [ViewState], in block: () -> Void, and rowBlock: (_ rowView: KHListRowView<Mod>, _ registry: inout [ViewState]) -> Void)
    {
        if let i = rowIndex {
            
            if i < self._entries.count, let rowView = self._entries[i].view {
                rowBlock(rowView, &registry)
            }
            
        } else {
            
            // self
            
            ViewState.registerStateForChanges(self._state, in: &registry)
            block()
                        
            // children
            
            for entry in self._entries {
                guard let rowView = entry.view else {
                    continue
                }
                rowBlock(rowView, &registry)
            }
        }
    }
}

extension KHListGroupView: KHListViewState_Delegate
{
    func commitChanges(_ changes: KHListViewModChanges)
    {
        self._state.notify(self.group)
        
        // reload config
        if  changes.contains(.config) {
            self._config = self.group.config
            self._configure()
            self._updateLastSeparatorVisibility()
        }
        
        if  changes.contains(.colors) {
            self._setColors()
            self._setSeparatorsColor()
        }
    }
}

extension KHListGroupView: KHListRowView_Delegate
{
    func selectingRow(_ selecting: Bool, at index: Int)
    {
        let lastIndex = self._entries.count - 1
        guard index <= lastIndex else {
            return
        }
        
        let last = index == lastIndex
        let entry = self._entries[index]
        
        // prev separator view
        if let separatorView = entry.prevSeparatorView, separatorView.setNextRowSelected(selecting) {
            separatorView.backgroundColor = separatorView.selected ? self.group.selectedSeparatorColor : self.group.separatorColor
        }
        
        // next separator view
        if let separatorView = entry.nextSeparatorView, separatorView.setPrevRowSelected(selecting) {
            separatorView.backgroundColor = separatorView.selected ? self.group.selectedSeparatorColor : last ? (self.group.lastSeparatorColor ?? self.group.separatorColor) : self.group.separatorColor
        }
    }
    
    func didSelectRow(at index: Int)
    {
        guard index < self._entries.count else {
            return
        }
        
        let entry = self._entries[index]
        
        guard let rowView = entry.view else {
            return
        }
        
        let indexPath = KHListViewIndexPath(group: self.index, row: index)
        
        self._delegate?.listViewDidSelectRow(KHListViewActionAdapter(rowView: rowView), at: indexPath, associatedData: rowView.row.associatedData)
    }
    
    func didToggleRow(at index: Int)
    {
        guard index < self._entries.count else {
            return
        }
        
        let entry = self._entries[index]
        
        guard let rowView = entry.view else {
            return
        }
        
        let indexPath = KHListViewIndexPath(group: self.index, row: index)
        
        self._delegate?.listViewDidToggleRow(KHListViewActionAdapter(rowView: rowView), at: indexPath, associatedData: rowView.row.associatedData)
    }
}

private protocol KHListRowView_Delegate: AnyObject
{
    func selectingRow(_ selecting: Bool, at index: Int)
    func didSelectRow(at index: Int)
    func didToggleRow(at index: Int)
}

private final class KHListRowView<Mod: KHListView_Mod>: KHControl
{
    var padding: UIEdgeInsets = .zero
    
    private(set) var index: Int
    private(set) var row: KHListView_Row
    
    typealias ViewState = KHListViewState<Mod>
    typealias StaticMod = ViewState.StaticMod
    
    func updateColors()
    {
        self._setColors()
        self._setCellsColors()
    }
    
    func appendMods(_ mods: [StaticMod], with registry: inout [ViewState])
    {
        self._changeMods(with: &registry) {
            self._state.add(mods)
        }
    }
    
    func removeMods(_ mods: [StaticMod], with registry: inout [ViewState])
    {
        self._changeMods(with: &registry) {
            self._state.remove(mods)
        }
    }
    
    func removeAllMods(with registry: inout [ViewState])
    {
        self._changeMods(with: &registry) {
            self._state.removeAllMods()
        }
    }
    
    // MARK: - Init
    
    init(with index: Int, row: KHListView_Row, delegate: KHListRowView_Delegate?, mods: [StaticMod])
    {
        self._state = .init(with: mods)
        self._state.notify(row)
        
        let config = row.config
        
        self.index = index
        self.row = row
        
        self._config = config
        self._delegate = delegate
        
        super.init(frame: .standard)
        
        self._state.parent = self
        
        self._configure()
        self._setColors()
        self._populate()
        self._setCellsColors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    var layoutScheme: [CGFloat]?
    
    func createLayoutScheme(with anotherScheme: [CGFloat]?) -> [CGFloat]
    {
        // #1: calculate minWidth
        
        var minWidths: [CGFloat] = []
        if let scheme = anotherScheme {
            
            let count = scheme.count
            let entries = self._entries
            for i in 0..<entries.count {
                let entry = entries[i]
                let minWidth = i < count ? scheme[i] : 0
                
                minWidths.append(max(minWidth, entry.safeCellMinWidth))
            }
            
        } else {
            
            for entry in self._entries {
                minWidths.append(entry.safeCellMinWidth)
            }
        }
        
        self.layoutScheme = minWidths
        
        return minWidths
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if  self._size != self.size || self._needs {
            self._size  = self.size
            self._needs = false
            
            self._layout(with: self.padding)
        }
    }
    
    override func setNeedsLayout()
    {
        self._needs = true
        super.setNeedsLayout()
    }
    
    // MARK: - Subclassing
    
    override func isBeingSelected(_ selecting: Bool)
    {
        self._delegate?.selectingRow(selecting, at: self.index)
        
        for entry in self._entries {
            entry.cell.updateColors(selected: selecting)
        }
    }
    
    override func hasBeenSelected()
    {
        guard let delegate = self._delegate else {
            return
        }
        
        self.selected ? delegate.didSelectRow(at: self.index) : delegate.didToggleRow(at: self.index)
    }
    
    // MARK: - Internal
    
    private var _size: CGSize?
    private var _needs = true
    private var _state: KHListViewState<Mod>
    private var _config: KHListViewRowConfig
    private var _entries: [Entry] = []
    private weak var _delegate: KHListRowView_Delegate?
    
    private struct Entry
    {
        var cell: KHListView_Cell
        weak var cellView: KHView?
        
        var safeCellMinWidth: CGFloat
        {
            return self.cell.visible ? self.cell.minWidth : 0
        }
        
        var safeCellStretchability: CGFloat
        {
            return self.cell.visible ? self.cell.stretchability : 0
        }
    }
    
    private func _configure()
    {
        let config = self._config

        if  config.borderWidth > 0 {
            self.layer.borderWidth = config.borderWidth
        }
        if  config.selectedBorderWidth > 0 {
            self.selectedViewBorderWidth = config.selectedBorderWidth
        }
        if  config.cornerRadius > 0 {
            KHViewHelper.setCornerRadius(config.cornerRadius, to: self)
            self.selectedViewCornerRadius = config.cornerRadius
            self.clipsToBounds = true
        } else {
            self.clipsToBounds = false
        }
        
        self.toggleEnabled = true
    }
    
    private func _setColors()
    {
        let row = self.row
        let config = self._config
        
        self.backgroundColor = row.backgroundColor
        
        if  config.borderWidth > 0 {
            self.layer.borderColor = row.borderColor?.cgColor
        }
        
        self.selectedBackgroundColor = row.selectedBackgroundColor
        
        if  config.selectedBorderWidth > 0 {
            self.selectedViewBorderColor = row.selectedBorderColor
        }
    }
    
    private func _setCellsColors()
    {
        let selected = self.selected
        for entry in self._entries {
            entry.cell.updateColors(selected: selected)
        }
    }
    
    private func _populate()
    {
        var entries: [Entry] = []
        let cells = self.row.cells
        for i in 0..<cells.count {
            
            let cell = cells[i]
            self._state.notify(cell)
            
            let view = cell.createView()
            self.addSubview(view)
            entries.append(Entry(cell: cell, cellView: view))
        }
        
        self._entries = entries
    }
    
    private class LayoutItem
    {
        private(set) weak var view: KHView?
        var minWidth: CGFloat
        private(set) var stretchability: CGFloat
        private(set) var visible: Bool
        
        init(view: KHView, minWidth: CGFloat = 0, stretchability: CGFloat = 0, visible: Bool)
        {
            self.view = view
            self.minWidth = minWidth
            self.stretchability = stretchability
            self.visible = visible
        }
    }
    
    private func _layout(with contentInset: UIEdgeInsets)
    {
        let clearance = self.row.config.clearance
        var stretchableItems: [LayoutItem] = []
        var minWidth: CGFloat = 0
        var layoutItems: [LayoutItem] = []
        let layoutScheme = self.layoutScheme ?? []
        
        // #1: calculate minWidth
        // find flexible cells
        // create layout state
        let entries = self._entries
        for i in 0..<entries.count {
            let entry = entries[i]
        
            if  let view = entry.cellView {
                let item = LayoutItem(view: view,
                                      minWidth: i < layoutScheme.count ? layoutScheme[i] : entry.safeCellMinWidth,
                                      stretchability: entry.safeCellStretchability,
                                      visible: entry.cell.visible)
                
                layoutItems.append(item)
                minWidth += item.minWidth
                if  item.stretchability > 0 {
                    stretchableItems.append(item)
                }
            }
        }
        
        guard minWidth > 0, layoutItems.count > 0 else {
            return
        }
        
        // #2: calculate maxHeight
        // layout views by width
        var maxHeight: CGFloat = 0
        let maxWidth = self.width - contentInset.left - contentInset.right - clearance * CGFloat(layoutItems.count - 1)
        if  maxWidth < minWidth || stretchableItems.count == 0 { // rare case, should not be possible
            
            let ratio = maxWidth / minWidth
            
            Self._layoutItems(layoutItems, with: clearance, maxHeight: &maxHeight, in: self.bounds, padding: contentInset) { $0.minWidth * ratio }
            
        } else {
            
            if  stretchableItems.count == 1 {
                stretchableItems.last?.minWidth += maxWidth - minWidth
                
            } else {
                
                var maxStretchability: CGFloat = 0
                for item in stretchableItems {
                    maxStretchability += item.stretchability
                    minWidth -= item.minWidth
                }
                
                // update flexible cells min width
                let ratio = (maxWidth - minWidth) / maxStretchability
                for item in stretchableItems {
                    item.minWidth = item.stretchability * ratio
                }
            }
            
            Self._layoutItems(layoutItems, with: clearance, maxHeight: &maxHeight, in: self.bounds, padding: contentInset) { $0.minWidth }
        }
        
        // #3: set row height
        // update height of all cells
        
        let  height = maxHeight.pixelRound(.up)
        self.height = height + contentInset.top + contentInset.bottom
        
        for item in layoutItems {
            item.view?.height = height
        }
        
        // update corner radius if required
        KHViewHelper.setCornerRadius(self._config.cornerRadius, to: self)
    }
    
    private func _changeMods(with registry: inout [ViewState], in block: () -> Void)
    {
        ViewState.registerStateForChanges(self._state, in: &registry)
        block()
    }
    
    // MARK: - Class Private
    
    private static func _layoutItems(_ items: [LayoutItem], with clearance: CGFloat, maxHeight: inout CGFloat, in bounds: CGRect, padding: UIEdgeInsets, widthBlock: (_ item: LayoutItem) -> CGFloat)
    {
        var left: CGFloat = padding.left
        for item in items {
            
            guard let view = item.view else {
                return
            }
            
            let inset = padding.left(left)
            if  item.visible {
                
                view.frame = bounds.inframe(.init(width: widthBlock(item)), .left, inset).pixelRound()
                view.alpha = 1
                view.forceLayout()
                
                left = view.right + clearance
                
                if  maxHeight < view.height {
                    maxHeight = view.height
                }
                
            } else {
                view.frame = bounds.inframe(.init(width: 1), .left, inset).width(0).pixelRound()
                view.alpha = 0
            }
        }
    }
}


extension KHListRowView: KHListViewState_Delegate
{
    func commitChanges(_ changes: KHListViewModChanges)
    {
        // self
        
        self._state.notify(self.row)
        
        if  changes.contains(.config) {
            self._config = self.row.config
            self._configure()
        }
        
        if  changes.contains(.colors) {
            self._setColors()
        }
        
        // children
        
        for entry in self._entries {
            self._state.notify(entry.cell)
        }
        
        if  changes.contains(.colors) {
            self._setCellsColors()
        }
    }
}




// ********** STRUCTURES ********** //

fileprivate protocol KHListViewState_Delegate: AnyObject
{
    func commitChanges(_ changes: KHListViewModChanges)
}

fileprivate final class KHListViewState<Mod: KHListView_Mod>
{
    struct StaticMod: Equatable
    {
        let mod: Mod
        let changes: KHListViewModChanges
        
        init(_ mod: Mod, _ changes: KHListViewModChanges)
        {
            self.mod = mod
            self.changes = changes
        }
    }
    
    func beginChanges() -> Bool
    {
        guard !self._changing else {
            return false
        }
        
        self._changing = true
        self._changes = []
        self._addMods = []
        self._delMods = []
        self._mdState = self._stState
        
        return true
    }
    
    func commitChanges() -> Bool
    {
        guard self._changing else {
            return false
        }
        
        var stState = self._stState
        let mdState = self._mdState
        var changes: KHListViewModChanges = []
        var addMods: [Mod] = []
        var delMods: [Mod] = []
        
        for mod in mdState { // adding
            if !stState.contains(mod) {
                addMods.append(mod.mod)
                changes.insert(mod.changes)
            } else {
                stState.removeAll { $0 == mod }
            }
        }
        
        for mod in stState { // removing
            delMods.append(mod.mod)
            changes.insert(mod.changes)
        }
        
        self._changing = false
        self._addMods = addMods
        self._delMods = delMods
        self._changes = changes
        self._stState = self._mdState
        
        self.parent?.commitChanges(self._changes)
        
        return true
    }
    
    func add(_ mods: [StaticMod])
    {
        guard self._changing else {
            return
        }
        
        for mod in mods {
            if self._mdState.contains(mod) {
                continue
            }
            self._mdState.append(mod)
        }
    }
    
    func remove(_ mods: [StaticMod])
    {
        guard self._changing else {
            return
        }
        
        for mod in mods {
            self._mdState.removeAll { $0.mod == mod.mod }
        }
    }
    
    func removeAllMods()
    {
        guard self._changing else {
            return
        }
        
        self._mdState = []
    }
    
    func notify<Target: KHListView_StateSensitive>(_ target: Target)
    {
        var mods: [Mod] = []
        for staticMod in self._stState {
            mods.append(staticMod.mod)
        }
        
        target.didChangeState(mods, adding: self._addMods, removing: self._delMods)
    }
    
    var currentState: [StaticMod]
    {
        return self._stState
    }
    
    var lastChanges: KHListViewModChanges
    {
        return self._changes
    }
    
    weak var parent: (any KHListViewState_Delegate)?
    
    // MARK: - Class Public
    
    static func convertToStatic(mods: [Mod]) -> [StaticMod]
    {
        var newMods: [StaticMod] = []
        for mod in mods {
            if newMods.contains(where: { $0.mod == mod }) {
                continue
            }
            newMods.append(.init(mod, mod.changes))
        }
        return newMods
    }
    
    static func registerStateForChanges(_ viewState: KHListViewState, in registry: inout [KHListViewState])
    {
        if  viewState.beginChanges() {
            registry.append(viewState)
        }
    }
    
    // MARK: - Init
    
    init(with mods: [StaticMod])
    {
        self._stState = mods
    }
    
    convenience init(with mods: [Mod])
    {
        self.init(with: Self.convertToStatic(mods: mods))
    }
    
    // MARK: - Private
    
    private var _stState: [StaticMod] = []
    private var _mdState: [StaticMod] = []
    private var _addMods: [Mod] = []
    private var _delMods: [Mod] = []
    private var _changes: KHListViewModChanges = []
    
    private var _changing: Bool = false
}







// ********* EXTENSIONS ********** //

extension KHListView_ContentProvider
{
    var backgroundColor: UIColor? { nil }
    var borderColor: UIColor? { nil }
    
    func createHeaderView() -> KHListView_OpenView? { nil }
    func createFooterView() -> KHListView_OpenView? { nil }
}

extension KHListView_Mod
{
    var changes: KHListViewModChanges {
        return []
    }
    
    func isFound(in state: [any KHListView_Mod]) -> Bool
    {
        for mod in state {
            if let mod = mod as? Self, self == mod {
                return true
            }
        }
        return false
    }
}

extension KHListView_StateSensitive
{
    func didChangeState(_ state: [any KHListView_Mod], adding: [any KHListView_Mod], removing: [any KHListView_Mod]) {}
}

extension KHListView_Group
{
    func createHeaderView() -> KHView? {
        return nil
    }
    func createFooterView() -> KHView? {
        return nil
    }
    var backgroundColor: UIColor? {
        return nil
    }
    var borderColor: UIColor? {
        return nil
    }
    var separatorColor: UIColor? {
        return nil
    }
    var lastSeparatorColor: UIColor? {
        return nil
    }
    var selectedSeparatorColor: UIColor? {
        return nil
    }
}

extension KHListView_Row
{
    var layoutID: String? {
        return nil
    }
    var initialState: [any KHListView_Mod] {
        return []
    }
    var initiallyDisabled: Bool {
        return false
    }
    var associatedData: Any?
    {
        return nil
    }
    var backgroundColor: UIColor? {
        return nil
    }
    var borderColor: UIColor? {
        return .gray
    }
    var selectedBackgroundColor: UIColor? {
        return .gray
    }
    var selectedBorderColor: UIColor {
        return .gray
    }
}

extension KHListView_Cell
{
    var stretchability: CGFloat {
        return 0
    }
    
    var visible: Bool {
        return true
    }
    
    func updateColors(selected: Bool) {}
}
