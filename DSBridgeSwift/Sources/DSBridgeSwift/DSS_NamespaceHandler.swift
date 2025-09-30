//
//  File.swift
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/17.
//

import Foundation

public typealias DSS_HandlerMethod = @Sendable ([String: Any]?) async -> Sendable?

public protocol DSS_NamespaceHandler {
    var dss_namespace: String { get }
    
    func dss_methodForName(_ dss_methodName: String) -> DSS_HandlerMethod?
}
