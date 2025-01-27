//
//  File.swift
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/20.
//

import Foundation

@propertyWrapper
public final class DSS_AutomicInt {
    
    var dss_rawValue: Int
    
    let dss_lock: DispatchSemaphore = .init(value: 1)
    
    public var wrappedValue: Int {
        dss_lock.wait()
        defer { dss_lock.signal() }
        let dss_retValue = dss_rawValue
        dss_rawValue += 1
        return dss_retValue
    }
    
    public init(wrappedValue: Int) {
        self.dss_rawValue = wrappedValue
    }
}
