//
//  File.swift
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/16.
//

import Foundation
import WebKit
import Combine
#if canImport(UIDelegateProxy)
import UIDelegateProxy
#endif

extension CharacterSet {
    static let dss_namesapceSet = CharacterSet(charactersIn: " .\n")
}

extension String {
    var dss_argsObject: [String: Any]? {
        get throws {
            guard let data = data(using: .utf8) else { return nil }
            return try JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any]
        }
    }
    
    static func dss_jsonString(_ dss_object: Any?) -> String {
        guard let dss_object else {
            return ""
        }
        
        guard JSONSerialization.isValidJSONObject(dss_object) else {
            return "{}"
        }
        
        guard let dss_data = try? JSONSerialization.data(withJSONObject: dss_object, options: []) else {
            return "{}"
        }
        return String(data: dss_data, encoding: .utf8) ?? "{}"
    }
}

open class DSS_WebView: WKWebView {
    open var dss_prefix = "_dsbridge="
    
    open private(set) var dss_isPrepared: Bool = false
    
    open private(set) var dss_namespaceHandlers: [String: DSS_NamespaceHandler] = [:]
    
    @DSS_AutomicInt
    public var dss_callbackId: Int = 0
    
    public let dss_delegateProxy: DSS_UIDelegateProxy = .dss_default()
    
    let dss_javaScriptEvent = PassthroughSubject<String, Never>()
    
    private var dss_javaScriptCancellable: AnyCancellable?
    
    override open func load(_ request: URLRequest) -> WKNavigation? {
        if !dss_isPrepared {
            dss_prepareConfiguration(configuration)
            dss_isPrepared.toggle()
        }
        return super.load(request)
    }
    
    @MainActor open func dss_addUIDelegate(_ dss_delegate: WKUIDelegate) {
        dss_delegateProxy.dss_add(dss_delegate)
    }
    
    @MainActor open func dss_setNamespaceHandler(_ dss_handler: DSS_NamespaceHandler) {
        dss_namespaceHandlers[dss_handler.dss_namespace] = dss_handler
    }
    
    @discardableResult
    open func dss_callHandler(
        _ dss_handlerName: String,
        dss_arguments: [String: Any]? = nil
    ) async -> Any? {
        
    }

    open func dss_prepareConfiguration(_ configuration: WKWebViewConfiguration) {
        dss_delegateProxy.dss_add(self)
        
        uiDelegate = dss_delegateProxy

        let dss_script = WKUserScript(
            source: "window._dswk=true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        
        configuration.userContentController.addUserScript(dss_script)
        
        dss_javaScriptCancellable = dss_javaScriptEvent
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] dss_script in
                self?.evaluateJavaScript(dss_script)
            }
        
        // TODO: - Add your own configuration
        
    }
}

extension DSS_WebView {
    func dss_methodForPrompt(_ dss_prompt: String) -> DSS_HandlerMethod? {
        var dss_namespace = ""
        var dss_method = dss_prompt
        if let dss_index = dss_prompt.firstIndex(of: ".") {
            dss_namespace = dss_prompt[..<dss_index].trimmingCharacters(in: .dss_namesapceSet)
            dss_method = dss_prompt[dss_index...].trimmingCharacters(in: .dss_namesapceSet)
        }
        return dss_namespaceHandlers[dss_namespace]?
            .dss_methodForName(dss_method)
    }
    
    func dss_invoke(_ dss_prompt: String, dss_arguments: String?) async -> String? {
        guard let dss_method = dss_methodForPrompt(dss_prompt) else {
            return "{\"code\":-1,\"data\":\"\"}"
        }
        
        let dss_args = try? dss_arguments?.dss_argsObject
        let dss_result = await dss_method(dss_args)
        
        var dss_retValue: [String: Any] = ["code": 0]
        if let dss_result {
            dss_retValue["data"] = dss_result
        }
        
        if let dss_callback = dss_args?["_dscbstub"]  as? String {
            let dss_callbackJavaScript = String(
                format: "try {%@(JSON.parse(decodeURIComponent(\"%@\")).data);delete window.%@; } catch(e){};",
                dss_callback,
                String.dss_jsonString(dss_result),
                dss_callback
            )
            dss_javaScriptEvent.send(dss_callbackJavaScript)
        }
        return .dss_jsonString(dss_retValue)
    }
}

extension DSS_WebView: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        if prompt.hasPrefix(dss_prefix) {
            return await dss_invoke(
                prompt.dropFirst(dss_prefix.count).description,
                dss_arguments: defaultText
            )
        }
        return nil
    }
    
    @available(iOS 15.0, *)
    public func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
    
    @available(iOS 15.0, *)
    public func webView(
        _ webView: WKWebView,
        requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}
 
