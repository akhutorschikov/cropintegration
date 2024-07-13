//
//  KHDashSlider.swift
//  kh-kit
//
//  Created by Alex Khuala on 29.08.23.
//

import UIKit

protocol KHDashSlider_Delegate: AnyObject
{
    func dashSlider(_ slider: KHDashSlider, didChangeValueWhileScrolling scrolling: Bool)

    func dashSliderWillBeginUpdates(_ slider: KHDashSlider) // optional
    func dashSliderDidFinishUpdates(_ slider: KHDashSlider) // optional
}

final class KHDashSlider: KHView
{
    var mainColor: UIColor?
    {
        didSet {
            self._cursorView?.backgroundColor = self.mainColor
            self._entries.forEach { $1.view.lineColor = self.mainColor }
            self._titleLabel?.textColor = self.mainColor
        }
    }
    
    var enabled: Bool = true
    {
        didSet {
            self._scrollView?.alpha = self.enabled ? 1.0 : 0.6
            self.isUserInteractionEnabled = self.enabled
        }
    }

    var value: CGFloat
    {
        get {
            if  self._config.infinite {
                return self._innerValue(for: self._value)
            } else {
                return max(self.inputData.minValue, min(self.inputData.maxValue, self._value))
            }
        }
        set {
            if  self._setValue(newValue), let scrollView = self._scrollView {
                self._updateContentOffset(for: scrollView)
                self._updateUnitsVisibleRange(for: scrollView)
                self._updateTitleLabel()
            }
        }
    }
    
    var flipped: Bool = false
    {
        didSet {
            guard self.flipped != oldValue else {
                return
            }
            self._scrollView?.transform = self.flipped ? .init(scaleX: -1, y: 1) : .identity
            self._updateTitleLabel()
        }
    }
    
    var text: String
    {
        var value = self.value
        
        if  self.flipped, self._config.invertedTextValueWhenFlipped {
            value = self.inputData.maxValue - (value - self.inputData.minValue)
            
            if  self._config.infinite, value == self.inputData.maxValue {
                value = self.inputData.minValue
            }
        }
        
        return String(format: self._config.textFormat, value)
    }
    
    var textLabelEnabled: Bool = true
    {
        didSet {
            guard self.textLabelEnabled != oldValue else {
                return
            }

            self._updateTitleLabel()
            self._titleLabel?.alpha = self.textLabelEnabled ? 1 : 0
            self._cursorView?.alpha = self.textLabelEnabled ? 0 : 1
            
            self._updateContainerMask()
        }
    }
    
    let inputData: InputData
    
    // MARK: - Init
    
    init(with inputData: InputData, delegate: KHDashSlider_Delegate, config: Config = .init())
    {
        self.inputData = inputData
        self._value = inputData.minValue
        self._config = config
        self._delegate = delegate
        self._infiniteContentOffset = config.infinite ? 100000 : 0
        self._interval = inputData.interval > 0 ? inputData.interval : 1
        self._period = config.unitSize.width > 0 ? config.unitSize.width : 1
        
        super.init(frame: .standard)
        
        self._configure()
        self._populate()
    }
    
    // MARK: - Methods
    
    func cancelAllEvents()
    {
        guard let view = self._scrollView, (view.isDragging || view.isDecelerating) else {
            return
        }
        self._endScrolling(scrollView: view)
    }
        
    // MARK: - Types
    
    struct Config: KHConfig_Protocol
    {
        var unitSize: CGSize = .init(20)
        var cursorHeight: CGFloat = 30
        var lineWidth: CGFloat = 1
        
        var infinite = false
        var accuracy: CGFloat?
        
        var significantPeriod: Int = 5
        
        var textFont: UIFont?
        var textFormat: String = "%g"
        
        var invertedTextValueWhenFlipped = false
    }
    
    struct InputData
    {
        let minValue: CGFloat
        let maxValue: CGFloat
        let interval: CGFloat
        
        fileprivate var width: CGFloat
        {
            self.maxValue - self.minValue
        }
        
        fileprivate func contains(_ value: CGFloat) -> Bool
        {
            value >= self.minValue && value <= self.maxValue
        }
        
        static let standard: Self = .init(minValue: 0, maxValue: 100, interval: 1)
    }
        
    // MARK: - Layout
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions)
    {
        let bounds = self.bounds
        
        if  let view = self._titleLabel {
            self._updateTitleLabelFrame(view)
        }
        
        if  let container = self._maskerView {
            container.frame = bounds
            self._updateContainerMaskRect(container)
        
            if  let view = self._scrollView {
                view.frame = container.bounds
                view.contentInset = .init(x: (view.width / 2).pixelRound())
                
                let top = ((view.height - self._config.unitSize.height) / 2).pixelRound()
                
                // update current units top position
                for entry in self._entries.values {
                    entry.view.top = top
                }
                
                self._unitTop = top
                self._updateContentOffset(for: view)
                self._updateUnitsVisibleRange(for: view)
            }
            
            if  let view = self._cursorView {
                let size = CGSize(self._config.lineWidth, self._config.cursorHeight)
                view.frame = container.bounds.inframe(size, .center).pixelRound()
            }
        }
    }
    
    // MARK: - Private
    
    private let _config: Config
    private var _value: CGFloat
    private let _period: CGFloat // always > 0
    private let _interval: CGFloat // always > 0
    private let _infiniteContentOffset: CGFloat
    private var _entries: [Int: Entry] = [:]
    
    private var _unitTop: CGFloat = 0
    private var _viewStack: [KHUnitView] = []
    private var _indexRange: Range<Int> = 0..<0
    
    private weak var _delegate: KHDashSlider_Delegate?
    
    private weak var _maskerView: UIView?
    private weak var _scrollView: UIScrollView?
    private weak var _cursorView: UIView?
    private weak var _titleLabel: KHLabel?
    
    private struct Entry
    {
        let view: KHUnitView
    }
    
    private func _configure()
    {
        self.isExclusiveTouch = true
    }
    
    private func _populate()
    {
        let view = self._addMaskerView()
        self._addScrollView(to: view)
        self._addCursorView(to: view)
        self._addTitleLabel()
    }
    
    private func _addMaskerView() -> UIView
    {
        let view = UIView()
        view.mask = KHRectMask()
        
        self.addSubview(view)
        self._maskerView = view
        
        return view
    }
    
    private func _addScrollView(to container: UIView)
    {
        let view = UIScrollView()
        view.alwaysBounceHorizontal = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delegate = self

        let count = (self.inputData.width / self._interval).round(.up)
        view.contentSize = .init(width: self._period * count + 2 * self._infiniteContentOffset)
        
        container.addSubview(view)
        self._scrollView = view
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(_didTapScrollView(_:))))
    }
    
    private func _addCursorView(to container: UIView)
    {
        let view = UIView()
        view.backgroundColor = self.mainColor ?? .black
        view.isUserInteractionEnabled = false
        view.alpha = 0
        
        container.addSubview(view)
        self._cursorView = view
    }
    
    private func _addTitleLabel()
    {
        let label = KHLabel()
        label.textAlignment = .left
        label.textColor = self.mainColor ?? .black
        label.font = self._config.textFont
        label.text = self.text
        
        self.addSubview(label)
        self._titleLabel = label
    }
    
    private func _updateTitleLabel()
    {
        guard self.textLabelEnabled, let view = self._titleLabel else {
            return
        }
        view.text = self.text
        self._updateTitleLabelFrame(view)
    }
    
    private func _updateTitleLabelFrame(_ titleLabel: KHLabel)
    {
        titleLabel.frame = self.bounds.inframe(.init(width: titleLabel.estimatedSize.width), .center).pixelRoundText()
    }
    
    private func _updateContainerMask()
    {
        guard let container = self._maskerView else {
            return
        }
        
        container.mask = self.textLabelEnabled ? KHRectMask() : nil
        self._updateContainerMaskRect(container)
    }
        
    private func _updateContainerMaskRect(_ container: UIView)
    {
        if  let mask = container.mask as? KHRectMask, let maskRect = self._titleLabel?.frame {
            mask.maskRect = maskRect.inset(.init(x: -self._period)).pixelRound()
            mask.frame = container.bounds
        }
    }
    
    private func _setValue(_ roughValue: CGFloat) -> Bool
    {
        var value: CGFloat = roughValue
        if  let accuracy = self._config.accuracy, accuracy > 0 {
            value = round(value / accuracy) * accuracy
        }
        
        guard self._value != value else {
            return false
        }
                
        self._value  = value
        return true
    }
    
    private func _tickOnce(increasing: Bool)
    {
        let newValue = self._value + self.inputData.interval * (increasing ? 1 : -1)
        
        guard self.inputData.contains(newValue) || self._config.infinite else {
            return
        }
            
        if  self._value != newValue {
            self._value  = newValue
            
            self._notifyOfValueChange()
            
            if  let view = self._scrollView {
                self._updateContentOffset(for: view, animated: true)
                self._updateUnitsVisibleRange(for: view)
            }
        }
        
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func _position(of scrollView: UIScrollView) -> CGFloat
    {
        return scrollView.contentOffset.x + scrollView.contentInset.left - self._infiniteContentOffset
    }

    private func _updateContentOffset(for scrollView: UIScrollView, value: CGFloat? = nil, animated: Bool = false)
    {
        let value = value ?? self._value
        let index = (value - self.inputData.minValue) / self._interval
        let shift = (index * self._period - scrollView.contentInset.left + self._infiniteContentOffset).pixelRound()
        
        scrollView.setContentOffset(.init(x: shift), animated: animated)
    }
    
    private func _resetContentOffsetAndValueWhenInfinite(for scrollView: UIScrollView)
    {
        guard self._config.infinite, !self.inputData.contains(self._value) else {
            return
        }
        
        let value = self._value(at: self._position(of: scrollView) / self._period)
        self._updateContentOffset(for: scrollView, value: self._innerValue(for: value))
        self._value = self._innerValue(for: self._value)
    }
    
    private func _stackView(_ view: KHUnitView)
    {
        view.isHidden = true
        self._viewStack.append(view)
    }
    
    private func _createUnitView(at index: Int) -> KHUnitView
    {
        var frame = self._config.unitSize.bounds
        frame.top = self._unitTop
        frame.left = frame.width * CGFloat(index) + self._infiniteContentOffset
        
        let view: KHUnitView
        if !self._viewStack.isEmpty {
            view = self._viewStack.removeLast()
            view.isHidden = false
        } else {
            view = KHUnitView(with: .init(lineWidth: self._config.lineWidth))
            view.clipsToBounds = false
            view.lineColor = self.mainColor
        }
        
        view.significant = index % self._config.significantPeriod == 0
        view.frame = frame
        
        return view
    }
    
    private func _updateUnitsVisibleRange(for scrollView: UIScrollView)
    {
        UIView.performWithoutAnimation {
            
            let lowerPosition = scrollView.contentOffset.x - self._infiniteContentOffset
            let upperPosition = lowerPosition + scrollView.width
            let count = Int((self.inputData.width / self._interval).round(.up)) + 1
                    
            // find new index range
            let indexRange: Range<Int>
            if  count > 0 {
                
                let reserve = 2
                
                var lower = Int((lowerPosition / self._period).round(.down)) - reserve
                var upper = Int((upperPosition / self._period).round(.up)) + reserve
                
                if !self._config.infinite {
                    
                    lower = min(count - 1, max(0, lower))
                    upper = min(count, max(0, upper))
                }
                
                indexRange = lower < upper ? lower..<upper : lower..<lower
            } else {
                indexRange = 0..<0
            }
            
            guard self._indexRange != indexRange else {
                return
            }
            
            // delete old unit views
            for i in self._indexRange where !indexRange.contains(i) {
                if  let entry = self._entries.removeValue(forKey: i) {
                    self._stackView(entry.view)
                }
            }
            
            // append new unit views
            for i in indexRange where !self._indexRange.contains(i) {
                let view = self._createUnitView(at: i)
                
                scrollView.addSubview(view)
                self._entries[i] = .init(view: view)
            }
            
            self._indexRange = indexRange
        }
    }
    
    private func _value(at index: CGFloat) -> CGFloat
    {
        return index * self._interval + self.inputData.minValue
    }
    
    private func _innerValue(for value: CGFloat) -> CGFloat
    {
        let width = self.inputData.width
        guard width > 0 else {
            return value
        }
        
        let lower = self.inputData.minValue
        var value = (value - lower).remainder(dividingBy: width) + lower
        if  value < lower {
            value += width
        }
        
        return value
    }
    
    private var _scrolling = false
    
    private func _endScrolling(scrollView: UIScrollView)
    {
        self._scrolling = false
        self._unregisterFeedbackGenerator()
        
        self._resetContentOffsetAndValueWhenInfinite(for: scrollView)
        self._updateUnitsVisibleRange(for: scrollView)
        self._updateContentOffset(for: scrollView, animated: self._config.accuracy != nil)
        
        self._notifyOfFinishUpdates()
    }
    
    private func _notifyOfValueChange()
    {
        self._updateTitleLabel()
        self._delegate?.dashSlider(self, didChangeValueWhileScrolling: self._scrolling)
    }

    private func _notifyOfFinishUpdates()
    {
        self._delegate?.dashSliderDidFinishUpdates(self)
    }
    
    private var _cachedScrollOffset: CGPoint = .zero
    private func _cacheScrollOffset(for scrollView: UIScrollView)
    {
        let lower = scrollView.contentInset.left * -1
        let upper = scrollView.contentSize.width + lower
        let shift = max(lower, min(upper, scrollView.contentOffset.x))
        
        self._cachedScrollOffset = scrollView.contentOffset.x(shift)
    }
    
    private class FeedbackGenerator
    {
        init(with period: CGFloat, in position: CGFloat)
        {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            
            self._generator = generator
            self._period = period
            self._lastPosition = Self._exactPosition(for: position, period: period)
        }
        
        func move(to position: CGFloat)
        {
            let delta = abs(self._lastPosition - position)
            if  delta > self._period - KHPixel || (!self._insideRange && delta < KHPixel) {
                self._lastPosition = Self._exactPosition(for: position, period: self._period)
                self._insideRange = abs(self._lastPosition - position) <= KHPixel
                self._generator.selectionChanged()
                self._generator.prepare()
            } else if self._insideRange, delta > KHPixel {
                self._insideRange = false
            }
        }
        
        private let _period: CGFloat
        private let _generator: UISelectionFeedbackGenerator
        private var _lastPosition: CGFloat
        private var _insideRange: Bool = true
        
        private static func _exactPosition(for rawPosition: CGFloat, period: CGFloat) -> CGFloat
        {
            (rawPosition / period).round() * period
        }
    }
    
    private var _feedbackGenerator: FeedbackGenerator?
    private func _registerFeedbackGenerator(for scrollView: UIScrollView)
    {
        self._feedbackGenerator = .init(with: self._period, in: self._position(of: scrollView))
    }

    private func _unregisterFeedbackGenerator()
    {
        self._feedbackGenerator = nil
    }
    
    // MARK: - System
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension KHDashSlider_Delegate
{
    func dashSliderWillBeginUpdates(_ slider: KHDashSlider) {}
    func dashSliderDidFinishUpdates(_ slider: KHDashSlider) {}
}




// *************************
// *************************  Gestures
// *************************

extension KHDashSlider
{
    @objc
    private func _didTapScrollView(_ gr: UITapGestureRecognizer)
    {
        guard gr.state == .ended else {
            return
        }
        
        let location = gr.location(in: self)
        let zone = self.bounds.size.width / 5;
        
        // in the middle zone from [2..3] do nothing
        
        if  location.x < zone * 2 {
            self._tickOnce(increasing: false)
        } else if location.x > zone * 3 {
            self._tickOnce(increasing: true)
        }
    }
}

// *************************
// *************************  Scrolling
// *************************


extension KHDashSlider: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) 
    {
        if !self._scrolling {
            self._scrolling = true
            self._registerFeedbackGenerator(for: scrollView)
            self._delegate?.dashSliderWillBeginUpdates(self)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) 
    {
        guard self._scrolling else {
            if  scrollView.isDecelerating {
                scrollView.contentOffset = self._cachedScrollOffset
            } else {
                self._updateUnitsVisibleRange(for: scrollView)
            }
            return
        }
        
        let position = self._position(of: scrollView)
        let index = position / self._period
        
        self._feedbackGenerator?.move(to: position)

        if  self._setValue(self._value(at: index)) {
            self._updateUnitsVisibleRange(for: scrollView)
            self._notifyOfValueChange()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) 
    {
        guard self._scrolling else {
            return
        }
        self._endScrolling(scrollView: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) 
    {
        guard self._scrolling, !decelerate else {
            self._cacheScrollOffset(for: scrollView)
            return
        }
        self._endScrolling(scrollView: scrollView)
    }
    
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) 
//    {
//        self._updateUnitsVisibleRange(for: scrollView)
//    }
}



// *************************
// *************************
// *************************


fileprivate class KHUnitView: KHView
{
    var lineColor: UIColor?
    {
        didSet {
            guard self.lineColor != oldValue else {
                return
            }
            self._lineView?.backgroundColor = self.lineColor ?? .black
        }
    }
    
    var significant: Bool = false
    {
        didSet {
            guard self.significant != oldValue else {
                return
            }
            self._lineView?.alpha = self._lineViewAlpha
        }
    }
    
    init(with config: Config)
    {
        self._config = config
        
        super.init(frame: .standard)
        
        self._configure()
        self._populate()
    }
    
    override func layout(with contentInset: UIEdgeInsets, options: KHView.LayoutOptions) 
    {
        let bounds = self.bounds
        
        if  let view = self._lineView {
            let lfix = 0.001
            view.frame = bounds.width(lfix).inframe(.init(width: self._config.lineWidth), .center).pixelRound()
        }
    }
    
    struct Config: KHConfig_Protocol
    {
        var lineWidth: CGFloat = 1
    }
    
    // MARK: - Private

    private var _config: Config
    private weak var _lineView: UIView?
    
    private var _lineViewAlpha: CGFloat
    {
        self.significant ? 1 : 0.5
    }
    
    private func _configure()
    {
        self.clipsToBounds = false
    }
    
    private func _populate()
    {
        self._addLineView()
    }
    
    private func _addLineView()
    {
        let view = UIView()
        view.backgroundColor = self.lineColor ?? .black
        view.alpha = self._lineViewAlpha
        
        self.addSubview(view)
        self._lineView = view
    }

    // MARK: - System
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
