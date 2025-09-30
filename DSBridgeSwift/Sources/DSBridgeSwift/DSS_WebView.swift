//
//  File.swift
//  DSBridgeSwift
//
//  Created by mayong on 2025/1/16.
//

import Combine
import Foundation
import WebKit

extension CharacterSet {
    static let dss_namesapceSet = CharacterSet(charactersIn: " .\n")
}

extension String {
    var dss_jsonDictionary: [String: Any]? {
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
    
    open private(set) var dss_namespaceHandlers: [String: DSS_NamespaceHandler] = [:]
    
    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        dss_prepareConfiguration(configuration)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func dss_prepareConfiguration(_ configuration: WKWebViewConfiguration) {
        uiDelegate = self

        let dss_script = WKUserScript(
            source: "window._dswk=true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        
        configuration.userContentController.addUserScript(dss_script)
        
        dss_javaScriptCancellable = dss_javaScriptEvent
            .delay(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] dss_script in
                self?.evaluateJavaScript(dss_script)
            }
        
        // TODO: - Add your own configuration
    }
    
    @DSS_AutomicInt
    public var dss_callbackId: Int = 0

    private var dss_handlerMap: [String: DSS_HandlerMethod] = [:]

    let dss_javaScriptEvent = PassthroughSubject<String, Never>()
    
    private var dss_javaScriptCancellable: AnyCancellable?

    open func dss_setNamespaceHandler(_ dss_handler: DSS_NamespaceHandler) {
        dss_namespaceHandlers[dss_handler.dss_namespace] = dss_handler
    }
    
    @discardableResult
    open func dss_callHandler(
        _ dss_handlerName: String,
        dss_arguments: [String: Any]? = nil
    ) async -> Any? {
        let dss_callInfo = [
            "method": dss_handlerName,
            "data": String.dss_jsonString(dss_arguments),
            "callbackId": "\(dss_callbackId)"
        ]

//        let dss_task = Task {
//            try? await evaluateJavaScript(
//                String(format: "window._handleMessageFromNative(%@)", String.dss_jsonString(dss_callInfo))
//            )
//        }
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
    
    func dss_invoke(_ dss_originString: String, dss_arguments: String?) async -> String? {
        guard let dss_method = dss_methodForPrompt(dss_originString) else {
#if DEBUG
            print("DSBridgeSwift: \(#function) no method for prompt: \(dss_originString)")
#endif
            return "{\"code\":-1,\"data\":\"\"}"
        }

        do {
            let dss_args = try dss_arguments?.dss_jsonDictionary

            let dss_data = dss_args?["data"] as? [String: Any]

            let dss_result = await dss_method(dss_data)

            var dss_retValue: [String: Any] = ["code": 0]

            if let dss_result {
                dss_retValue["data"] = dss_result
            }

            if let dss_callback = dss_args?["_dscbstub"] as? String {
                let dss_callbackJavaScript = String(
                    format: "try {%@(JSON.parse(decodeURIComponent(\"%@\")).data);delete window.%@; } catch(e){};",
                    dss_callback,
                    String.dss_jsonString(dss_retValue),
                    dss_callback
                )
                dss_javaScriptEvent.send(dss_callbackJavaScript)
            }

            return .dss_jsonString(dss_retValue)
        } catch {
#if DEBUG
            print("DSBridgeSwift: \(#function) error: \(error)")
#endif
            return "{\"code\":-1,\"data\":\"\"}"
        }
    }
}

extension DSS_WebView: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        guard prompt.hasPrefix(dss_prefix) else {
            return nil
        }
        let dss_prefixIndex = prompt.index(
            prompt.startIndex,
            offsetBy: dss_prefix.count
        )
        return await dss_invoke(
            String(prompt[dss_prefixIndex...]),
            dss_arguments: defaultText
        )
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
 
