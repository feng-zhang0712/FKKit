import FKCoreKit
import UIKit

/// Demonstrates pluggable analytics contracts (`FKPluggableAnalytics*`).
final class FKPluggableAnalyticsExampleViewController: FKPluggableExampleBaseViewController {

  private let tracker = PluggableDemoAnalyticsTracker()
  private let uploader = PluggableDemoAnalyticsUploader()
  private let commonParams = PluggableDemoAnalyticsCommonParameters()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Analytics"

    tracker.onEvent = { [weak self] line in
      Task { @MainActor in self?.appendOutput(line) }
    }
    uploader.onUpload = { [weak self] line in
      Task { @MainActor in self?.appendOutput(line) }
    }
    tracker.setCommonParametersProvider(commonParams)
    tracker.setUploader(uploader)

    addActionButton("1) Build FKPluggableAnalyticsEvent manually") { [weak self] in
      let event = FKPluggableAnalyticsEvent(name: "custom_demo", parameters: ["foo": "bar"])
      self?.appendOutput("Event id=\(event.id) name=\(event.name) params=\(event.parameters)")
    }
    addActionButton("2) trackPageView") { [weak self] in
      self?.tracker.trackPageView("pluggable_analytics", parameters: ["section": "demo"])
    }
    addActionButton("3) trackClick") { [weak self] in
      self?.tracker.trackClick(element: "flush_button", page: "pluggable_analytics", parameters: nil)
    }
    addActionButton("4) trackEvent (custom)") { [weak self] in
      self?.tracker.trackEvent("purchase_intent", parameters: ["sku": "demo-001"])
    }
    addActionButton("5) flush() async → FKPluggableAnalyticsUploading") { [weak self] in
      Task { await self?.tracker.flush() }
    }
    addActionButton("6) FKPluggableAnalyticsCommonParametersProviding only") { [weak self] in
      let params = self?.commonParams.commonParameters() ?? [:]
      self?.appendOutput("Common params: \(params)")
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }
}
