import UIKit
import FKCoreKit

/// B6 — deeplink registration and simulated routing.
final class FKBusinessKitExampleDeeplinkRouteViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "DeeplinkRoute"
    kit.deeplink.register(
      FKDeeplinkRoute(id: "product", host: "example.com", pathPattern: "/product/*") { [weak self] context in
        Task { @MainActor in
          self?.appendLog("Matched product params=\(context.parameters)")
        }
        return true
      }
    )
    kit.deeplink.register(
      FKDeeplinkRoute(id: "promo", host: "example.com", pathPattern: "/promo/*") { [weak self] context in
        Task { @MainActor in
          self?.appendLog("Matched promo params=\(context.parameters)")
        }
        return true
      }
    )
    addActionButton("Route sample URLs") { [weak self] in
      let urls = [
        "https://example.com/product/42?ref=ad",
        "https://example.com/promo/spring?coupon=10",
        "https://example.com/unknown",
      ]
      for string in urls {
        guard let url = URL(string: string) else { continue }
        let handled = self?.kit.deeplink.route(url, source: .universalLink) ?? false
        self?.appendLog("\(string) → handled=\(handled)")
      }
    }
  }
}
