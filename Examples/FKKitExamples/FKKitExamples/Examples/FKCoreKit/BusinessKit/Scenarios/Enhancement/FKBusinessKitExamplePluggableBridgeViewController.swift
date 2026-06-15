import UIKit
import FKCoreKit

/// E2 — Pluggable adapters bridging BusinessKit lifecycle and analytics.
final class FKBusinessKitExamplePluggableBridgeViewController: FKBusinessKitExampleBaseViewController {
  private var lifecycleToken: FKPluggableObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "E2 PluggableBridge"
    let lifecycleAdapter = FKBusinessLifecyclePluggableAdapter(observer: kit.lifecycle)
    lifecycleToken = lifecycleAdapter.observe { [weak self] state in
      Task { @MainActor in
        self?.appendLog("Pluggable lifecycle: \(state.rawValue)")
      }
    }
    appendLog("Pluggable state: \(lifecycleAdapter.state.rawValue)")

    addActionButton("Enqueue via FKBusinessAnalyticsPluggableUploader") { [weak self] in
      guard let self else { return }
      self.kit.track.setUploader(FKBusinessKitDemoAnalyticsUploader(logger: { self.appendLog($0) }))
      let uploader = FKBusinessAnalyticsPluggableUploader(tracker: self.kit.track)
      Task {
        try? await uploader.upload(batch: [
          FKPluggableAnalyticsEvent(name: "pluggable_demo", parameters: ["scene": "E2"]),
        ])
        self.appendLog("Pluggable batch enqueued in BusinessKit buffer")
        await self.kit.track.flush()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      lifecycleToken?.cancel()
      lifecycleToken = nil
    }
  }
}
