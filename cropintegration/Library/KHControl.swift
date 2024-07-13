//
//  KHControl.swift
//  kh-kit
//
//  Created by Alex Khuala on 3/2/18.
//

import UIKit

fileprivate let KHControlTouchMoveLimit: CGFloat = 100;

open class KHControl: UIView
{
    // MARK: - Public properties
    
    public var enabled: Bool = true
    {
        didSet {
            if (self.enabled != oldValue) {
                self.alpha = self._normalAlpha
            }
        }
    }
    
/*!
     @discussion Allows deselect when selected and selected when unselected
 */
    public var toggleEnabled: Bool = false
    
    public var selected: Bool {
        set {
            self.setSelected(newValue, animated: false);
        }
        get {
            return self._selected;
        }
    }
    
    public var selectedBackgroundColor: UIColor?
    {
        set {
            self._defaultSelectedView.backgroundColor = newValue;
        }
        get {
            return self._defaultSelectedView.backgroundColor;
        }
    }
    public var selectedAlpha: CGFloat?; // alternative to selected background color
    public var animationDuration: TimeInterval      = 0.5;
    
    public var minimumTapInterval: TimeInterval? // When nil used default behaviour: animationDuration when animated or 0 when no animation
    
    public var selectedViewSquare: Bool             = false
    {
        didSet {
            self._updateDefaultSelectedViewFrame();
        }
    }
    public var selectedViewBorderWidth: CGFloat
    {
        set {
            self._defaultSelectedView.layer.borderWidth = newValue;
        }
        get {
            return self._defaultSelectedView.layer.borderWidth;
        }
    }
    public var selectedViewBorderColor: UIColor?
    {
        set {
            self._defaultSelectedView.layer.borderColor = newValue?.cgColor;
        }
        get {
            if let cgColor = self._defaultSelectedView.layer.borderColor {
                return UIColor(cgColor: cgColor);
            }
            
            return nil;
        }
    }
    public var selectedViewInset: KHInset           = .zero
    {
        didSet {
            self._updateDefaultSelectedViewFrame();
        }
    }
    public var selectedViewSize: CGSize             = .zero // alternative to "inset" property
    {
        didSet {
            self._updateDefaultSelectedViewFrame();
        }
    }
    public var selectedViewCornerRadius: CGFloat    = 0
    {
        didSet {
            self._updateDefaultSelectedViewCorderRadius();
        }
    }
    
    public var eventAreaInset: KHInset              = .zero;
    
    public var action: ((_ control: KHControl) -> Void)?
    
    public var longAction: ((_ control: KHControl) -> Void)?
    public var longActionDuration: TimeInterval = 1
    
    // MARK: - Public methods
    
    public func setSelected(_ selected: Bool, animated: Bool)
    {
        if !self.enabled && !self.selected {
            return;
        }
        
        self._selected = selected;
        
        func block() {
            self._setSelectedViewSelected(selected)
        }
        
        if (animated) {
            UIView.animate(withDuration: self.animationDuration, delay: 0, options: self._animationOptions, animations: block, completion: nil)
        } else {
            block()
        }
    }
    
    public func triggerSelection()
    {
        if !self.selected {
            self.selected = true;
        }
        
        self._callAction();
    }
    
    // MARK: - Overridable
    
    /*!
     @brief Update content state on selection. Animatable.
     @discussion Default implementation of this method does nothing. Use this method to update content when selection occurs. When control is selected with animation, this method executes inside animation block.
     */
    
    open func isBeingSelected(_ selecting: Bool)
    {
        // default implementation does nothing
    }
    
    /*!
     @brief Called before 'action'
     */
    open func hasBeenSelected()
    {
        // default implementation does nothing
    }
    
    // MARK: - Private properties
    
    private var _selected: Bool                     = false;
    private var _defaultSelectedView: UIView!;
    private var _touchesInProgress: Bool            = false;
    private var _touchesEndDate: Date?
//    private var _cachedViewAlpha: CGFloat?;
    private var _alphaSelected: Bool                = false
    
    private var _longActionTimer: Timer?
    
    private var touchesInProgress: Bool
    {
        set {
            if (_touchesInProgress != newValue) {
                _touchesInProgress  = newValue;
                
                if !self.selected {
                    self._setSelectedViewSelected(newValue)
                }
                
                if (newValue == true && self.longAction != nil) {
                    self._longActionTimer = Timer.scheduledTimer(withTimeInterval: self.longActionDuration, repeats: false, block: { (timer) in
                        timer.invalidate()
                        
                        self._selected = true;
                        self._callLongAction();
                        
                        self.touchesInProgress = false;
                    })
                } else {
                    self._longActionTimer?.invalidate()
                }
            }
        }
        get {
            return _touchesInProgress;
        }
    }
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame);
        
        let selectedView = UIView(frame: self.bounds);
        selectedView.alpha = 0.0;
        
        self.addSubview(selectedView);
        self._defaultSelectedView = selectedView;
        
        self.isExclusiveTouch = true;
        self.selectedBackgroundColor = UIColor.lightGray;
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews();
        
        self._updateCornerRadius();
        self._updateDefaultSelectedViewFrame();
        self._updateDefaultSelectedViewCorderRadius();
    }
    
    // MARK: - Internal
    
    private var _normalAlpha: CGFloat
    {
        return self.enabled ? 1.0 : 0.5
    }
    
    private var _animationOptions: UIView.AnimationOptions
    {
        var options: UIView.AnimationOptions = []
        if self.minimumTapInterval != nil {
            options.insert(.allowUserInteraction)
        }
        return options
    }
    
    private var _touchesAllowed: Bool
    {
        var allowed = true
        if let interval = self.minimumTapInterval, let date = self._touchesEndDate {
            allowed = -date.timeIntervalSinceNow > interval
        }
        return allowed
    }
    
    private func _setSelectedViewSelected(_ selected: Bool)
    {
        if (selected) {
            if !self._alphaSelected, let alpha = self.selectedAlpha {
                self._alphaSelected = true
                self.alpha = alpha
            }
        } else {
            if (self._alphaSelected) {
                self._alphaSelected = false
                self.alpha = self._normalAlpha
            }
        }
        
        self._defaultSelectedView.alpha = selected ? 1.0 : 0.0;
        self.isBeingSelected(selected);
    }
    
    private func _updateCornerRadius()
    {
        let maxCornerRadius = self.size.minSize / 2;
        
        if (self.layer.cornerRadius > maxCornerRadius) {
            self.layer.cornerRadius = maxCornerRadius;
        }
    }
    
    private func _updateDefaultSelectedViewFrame()
    {
        var frame = self.bounds;
        
        if (self.selectedViewSize.width > 0 && self.selectedViewSize.height > 0) {
            frame = self.bounds.inframe(self.selectedViewSize, .center, .zero);
        } else {
            frame = self.bounds.inset(self.selectedViewInset);
        }
        
        if (self.selectedViewSquare) {
            frame = frame.inframe(KHSize(frame.size.minSize), .center, .zero);
        }
        
        self._defaultSelectedView.frame = frame;
    }
    
    private func _updateDefaultSelectedViewCorderRadius()
    {
        self._defaultSelectedView.layer.cornerRadius = fmin(self._defaultSelectedView.size.minSize / 2, self.selectedViewCornerRadius);
    }
    
    private func _callAction()
    {
        self.hasBeenSelected()
        
        if let action = self.action {
            DispatchQueue.main.async {
                action(self);
            }
        }
    }
    
    private func _callLongAction()
    {
        if let action = self.longAction {
            DispatchQueue.main.async {
                action(self);
            }
        }
    }
    
    // MARK: - Touch events
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        return self.bounds.inset(self.eventAreaInset).contains(point);
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if (self.enabled && (self.toggleEnabled || !self.selected) && self._touchesAllowed) {
            self.touchesInProgress = true;
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first {
            
            let point = touch.location(in: self);
            let limit = KHControlTouchMoveLimit;
            let inset = self.eventAreaInset;
            
            if (point.x > self.width - inset.right + limit  || point.x < inset.left - limit ||
                point.y > self.height - inset.bottom + limit || point.y < inset.top - limit) {
                self.touchesInProgress = false;
            }
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.touchesInProgress = false;
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if (self.touchesInProgress) {
            
            self.layer.removeAllAnimations()
            self._touchesEndDate = Date()
            self._selected = self.toggleEnabled ? !self._selected : true
            self._callAction();
            
            self.touchesInProgress = false;
        }
    }
}
