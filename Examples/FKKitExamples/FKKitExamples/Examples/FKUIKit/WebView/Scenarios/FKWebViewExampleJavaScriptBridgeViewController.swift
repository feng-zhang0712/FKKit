import FKUIKit
import UIKit

/// Multi-handler bridge: JSON payloads JS → native, structured push native → JS via ``FKWebView/evaluateJavaScript(_:completion:)``.
final class FKWebViewExampleJavaScriptBridgeViewController: UIViewController, FKWebViewDelegate {
  private enum HandlerID {
    static let demo = "demo"
    static let analytics = "analytics"
  }

  private let logView = FKWebViewExampleSupport.makeEventLog()
  private var isPageReady = false
  private var pendingNativeEvents: [[String: Any]] = []

  private lazy var webView: FKWebView = {
    var configuration = FKWebViewConfiguration()
    configuration.javascript.bridge = FKJavaScriptBridge(handlers: [
      FKJavaScriptHandlerRegistration(name: "fkDemo", handlerID: HandlerID.demo),
      FKJavaScriptHandlerRegistration(name: "fkAnalytics", handlerID: HandlerID.analytics),
    ])
    let view = FKWebView(configuration: configuration)
    view.delegate = self
    return view
  }()

  private lazy var pushThemeButton: UIButton = {
    var config = UIButton.Configuration.gray()
    config.title = "Push theme"
    let button = UIButton(configuration: config)
    button.addTarget(self, action: #selector(pushThemeTapped), for: .touchUpInside)
    return button
  }()

  private lazy var pushProfileButton: UIButton = {
    var config = UIButton.Configuration.gray()
    config.title = "Push profile"
    let button = UIButton(configuration: config)
    button.addTarget(self, action: #selector(pushProfileTapped), for: .touchUpInside)
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "JavaScript bridge"
    view.backgroundColor = .systemGroupedBackground

    let caption = FKWebViewExampleSupport.makeCaptionLabel(
      "Top buttons push native → JS. Page buttons post to fkDemo / fkAnalytics. Watch both logs."
    )
    let nativeBar = UIStackView(arrangedSubviews: [pushThemeButton, pushProfileButton])
    nativeBar.axis = .horizontal
    nativeBar.spacing = 8
    nativeBar.distribution = .fillEqually
    nativeBar.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    view.addSubview(nativeBar)
    view.addSubview(container)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      nativeBar.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 8),
      nativeBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      nativeBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: nativeBar.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.48),

      logView.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    FKWebViewExampleSupport.loadBundledDemoHTML(named: "fkwebview-bridge", into: webView)
  }

  // MARK: - FKWebViewDelegate

  func webView(_ webView: FKWebView, didFinish url: URL?) {
    isPageReady = true
    flushPendingNativeEvents(into: webView)
    pushNativeEvent(
      into: webView,
      payload: ["type": "ready", "platform": "iOS", "timestamp": Date().timeIntervalSince1970]
    )
  }

  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage) {
    FKWebViewExampleSupport.append(
      "← JS handler=\(message.name) id=\(message.handlerID) body=\(FKWebViewExampleBridgeSupport.describe(message.body))",
      to: logView
    )

    switch message.handlerID {
    case HandlerID.demo:
      handleDemoMessage(webView, message: message)
    case HandlerID.analytics:
      handleAnalyticsMessage(message)
    default:
      FKWebViewExampleSupport.append("unknown handlerID=\(message.handlerID)", to: logView)
    }
  }

  // MARK: - Native → JS

  @objc private func pushThemeTapped() {
    let isDark = pushThemeButton.configuration?.title == "Push theme"
    let theme = isDark ? "dark" : "light"
    pushThemeButton.configuration?.title = isDark ? "Push light" : "Push theme"
    pushNativeEvent(
      into: webView,
      payload: ["type": "theme", "value": theme, "timestamp": Date().timeIntervalSince1970]
    )
    FKWebViewExampleSupport.append("→ native push theme=\(theme)", to: logView)
  }

  @objc private func pushProfileTapped() {
    pushNativeEvent(
      into: webView,
      payload: [
        "type": "profile",
        "profile": [
          "displayName": "FKKit Demo",
          "tier": "pro",
          "userId": "usr_demo_001",
        ] as [String: Any],
        "timestamp": Date().timeIntervalSince1970,
      ]
    )
    FKWebViewExampleSupport.append("→ native push profile", to: logView)
  }

  // MARK: - JS → Native routing

  private func handleDemoMessage(_ webView: FKWebView, message: FKJavaScriptMessage) {
    guard case .dictionary(let dict) = message.body,
      case .string(let action) = dict["action"] else {
      FKWebViewExampleSupport.append("fkDemo: missing action string", to: logView)
      return
    }

    switch action {
    case "ping":
      webView.evaluateJavaScript("appendLog('Native pong at ' + Date.now());") { [weak self] result in
        guard let self else { return }
        if case .failure(let error) = result {
          FKWebViewExampleSupport.append("evaluateJavaScript failed: \(error.localizedDescription)", to: self.logView)
        }
      }
      FKWebViewExampleSupport.append("fkDemo: ping → evaluateJavaScript pong", to: logView)

    case "submitOrder":
      if case .string(let requestId) = dict["requestId"] {
        FKWebViewExampleSupport.append("fkDemo: submitOrder requestId=\(requestId)", to: logView)
      }
      if case .dictionary(let order) = dict["order"],
        case .string(let sku) = order["id"],
        case .int(let quantity) = order["quantity"] {
        FKWebViewExampleSupport.append("fkDemo: parsed order sku=\(sku) qty=\(quantity)", to: logView)
      }

    case "getProfile":
      guard case .string(let requestId) = dict["requestId"] else {
        FKWebViewExampleSupport.append("fkDemo: getProfile missing requestId", to: logView)
        return
      }
      pushNativeEvent(
        into: webView,
        payload: [
          "type": "profileResponse",
          "requestId": requestId,
          "profile": [
            "displayName": "FKKit Demo",
            "tier": "pro",
            "email": "demo@fkkit.example",
          ] as [String: Any],
        ]
      )
      FKWebViewExampleSupport.append("fkDemo: getProfile → profileResponse requestId=\(requestId)", to: logView)

    default:
      FKWebViewExampleSupport.append("fkDemo: unhandled action=\(action)", to: logView)
    }
  }

  private func handleAnalyticsMessage(_ message: FKJavaScriptMessage) {
    guard case .dictionary(let dict) = message.body,
      case .string(let event) = dict["event"] else {
      FKWebViewExampleSupport.append("fkAnalytics: missing event", to: logView)
      return
    }
    var detail = "event=\(event)"
    if case .string(let screen) = dict["screen"] {
      detail += " screen=\(screen)"
    }
    if case .dictionary(let properties) = dict["properties"],
      case .string(let referrer) = properties["referrer"] {
      detail += " referrer=\(referrer)"
    }
    FKWebViewExampleSupport.append("fkAnalytics: \(detail)", to: logView)
  }

  private func pushNativeEvent(into webView: FKWebView, payload: [String: Any]) {
    guard isPageReady else {
      pendingNativeEvents.append(payload)
      return
    }
    guard let script = FKWebViewExampleBridgeSupport.evaluateNativeEventScript(payload: payload) else {
      FKWebViewExampleSupport.append("failed to encode native payload", to: logView)
      return
    }
    webView.evaluateJavaScript(script) { [weak self] result in
      guard let self else { return }
      if case .failure(let error) = result {
        FKWebViewExampleSupport.append("evaluateJavaScript failed: \(error.localizedDescription)", to: self.logView)
      }
    }
  }

  private func flushPendingNativeEvents(into webView: FKWebView) {
    let queue = pendingNativeEvents
    pendingNativeEvents = []
    for payload in queue {
      pushNativeEvent(into: webView, payload: payload)
    }
  }
}

// MARK: - Bridge helpers

private enum FKWebViewExampleBridgeSupport {
  static func describe(_ body: FKJavaScriptMessageBody) -> String {
    switch body {
    case .null: return "null"
    case .bool(let value): return String(value)
    case .int(let value): return String(value)
    case .double(let value): return String(value)
    case .string(let value): return "\"\(value)\""
    case .array(let items): return "[\(items.map(describe).joined(separator: ", "))]"
    case .dictionary(let dict):
      let pairs = dict.sorted { $0.key < $1.key }.map { "\($0.key): \(describe($0.value))" }
      return "{\(pairs.joined(separator: ", "))}"
    }
  }

  static func evaluateNativeEventScript(payload: [String: Any]) -> String? {
    guard JSONSerialization.isValidJSONObject(payload),
      let data = try? JSONSerialization.data(withJSONObject: payload),
      let json = String(data: data, encoding: .utf8) else {
      return nil
    }
    return "window.FKBridge.onNativeEvent(\(json));"
  }
}
