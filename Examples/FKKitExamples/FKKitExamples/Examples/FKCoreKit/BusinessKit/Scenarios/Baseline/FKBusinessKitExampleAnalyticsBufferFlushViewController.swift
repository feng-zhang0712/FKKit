import UIKit
import FKCoreKit

/// B3 — file-backed analytics buffer with demo uploader and flush.
final class FKBusinessKitExampleAnalyticsBufferFlushViewController: FKBusinessKitExampleBaseViewController {
  private var lifecycleToken: FKBusinessObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "AnalyticsBufferFlush"
    kit.updateConfiguration { $0.analyticsFlushInterval = 5 }
    kit.track.setUploader(FKBusinessKitDemoAnalyticsUploader(logger: { [weak self] in self?.appendLog($0) }))
    kit.track.setCommonParametersProvider(FKBusinessKitDemoAnalyticsCommonParamsProvider())
    lifecycleToken = kit.lifecycle.observe { [weak self] state in
      Task { @MainActor in
        if state == .background {
          self?.appendLog("Background → flush")
          self?.kit.track.flush(completion: nil)
        }
      }
    }
    addInfoLabel("Flush on background is wired via lifecycle.observe.")
    addActionButton("Track page + click + custom") { [weak self] in
      self?.kit.track.trackPageView("DemoPage", parameters: ["scene": "B3"])
      self?.kit.track.trackClick("DemoButton", page: "DemoPage", parameters: nil)
      self?.kit.track.trackEvent("demo_custom", parameters: ["k": "v"])
      self?.appendLog("Events queued.")
    }
    addActionButton("Flush now (async)") { [weak self] in
      Task {
        await self?.kit.track.flush()
        self?.appendLog("Flush completed.")
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      lifecycleToken?.invalidate()
      lifecycleToken = nil
    }
  }
}
