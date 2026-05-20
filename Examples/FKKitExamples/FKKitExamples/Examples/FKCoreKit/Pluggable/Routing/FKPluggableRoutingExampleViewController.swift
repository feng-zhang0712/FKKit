import FKCoreKit
import UIKit

/// Demonstrates `FKDeeplinkParsing`, `FKRouteHandling`, and `FKDeeplinkRouting`.
final class FKPluggableRoutingExampleViewController: FKPluggableExampleBaseViewController {

  private let router = DemoDeeplinkRouter()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Routing"

    router.register(
      DemoProductRouteHandler { [weak self] context in
        self?.appendOutput("✅ product handler: path=\(context.pathComponents) query=\(context.queryItems)")
      }
    )
    router.register(
      DemoPromoRouteHandler { [weak self] context in
        self?.appendOutput("✅ promo handler: path=\(context.pathComponents)")
      }
    )

    addActionButton("1) Parse URL (FKDeeplinkParsing)") { [weak self] in
      let url = URL(string: "myapp://example.com/product/42?ref=push")!
      let parser = DemoDeeplinkParser()
      if let context = parser.parse(url: url) {
        self?.appendOutput("Parsed path=\(context.pathComponents), query=\(context.queryItems)")
      } else {
        self?.appendOutput("Parse returned nil")
      }
    }
    addActionButton("2) Open product deeplink (handled)") { [weak self] in
      self?.openLink("myapp://example.com/product/42?ref=email")
    }
    addActionButton("3) Open promo deeplink (handled)") { [weak self] in
      self?.openLink("myapp://example.com/promo/spring")
    }
    addActionButton("4) Open unknown path (notHandled)") { [weak self] in
      self?.openLink("myapp://example.com/unknown/page")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func openLink(_ string: String) {
    guard let url = URL(string: string) else {
      appendOutput("Invalid URL")
      return
    }
    let result = router.open(url: url)
    appendOutput("open(\(url.lastPathComponent)) → \(describe(result))")
  }

  private func describe(_ result: FKRouteHandlingResult) -> String {
    switch result {
    case .handled: return "handled"
    case .notHandled: return "notHandled"
    case .failed(let message): return "failed(\(message))"
    }
  }
}
