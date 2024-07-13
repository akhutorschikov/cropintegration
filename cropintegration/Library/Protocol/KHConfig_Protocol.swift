//
//  KHConfig_Protocol.swift
//  cropintegration
//
//  Created by Alex Khuala on 4.07.22.
//

protocol KHConfig_Protocol
{
    init()
    associatedtype Config = Self where Config:KHConfig_Protocol
    init(in block: (inout Config) -> Void)
    
    func modify(in block: (inout Config) -> Void) -> Config
}

extension KHConfig_Protocol
{
    init(in block: (inout Self) -> Void)
    {
        self.init()
        block(&self)
    }
    
    func modify(in block: (inout Self) -> Void) -> Self
    {
        var config = self
        block(&config)
        
        return config
    }
}
