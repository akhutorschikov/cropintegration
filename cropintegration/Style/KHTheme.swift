//
//  KHTheme.swift
//  cropintegration
//
//  Created by Alex Khuala on 11.06.22.
//

class KHTheme: KHTheme_Protocol
{
    enum Name: String
    {
        case gray
    }
    
    // MARK: - Public
    
    public static private(set) var color = KHPalette(.gray)
    
    public static func load(_ name: Name)
    {
        self.color = KHPalette(name)
        self._notifyListeners()
    }
    
    /*!
     @brief Subscribe to events
     */
    public static func addListener(_ listener: any KHTheme_Sensitive)
    {
        self._listeners.append(.init(listener: listener))
    }
    
    /*!
     @brief Unsubscribe from events
     */
    public static func removeListener(_ listener: any KHTheme_Sensitive)
    {
        self._listeners.removeAll { $0.listener === listener }
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Internal
    
    private struct Entry
    {
        weak var listener: (any KHTheme_Sensitive)?
    }
    
    private static var _listeners: [Entry] = []
    
    private static func _notifyListeners()
    {
        self._listeners.forEach { $0.listener?.didChangeTheme() }
    }
}
