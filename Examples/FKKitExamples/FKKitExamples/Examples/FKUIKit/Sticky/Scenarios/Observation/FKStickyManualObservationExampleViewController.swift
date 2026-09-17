import FKUIKit
import UIKit

/// Manual sticky drive with observesAutomatically = false.
final class FKStickyManualObservationExampleViewController: FKStickyExampleScrollPageViewController {
  private let strip = FKStickyExampleUI.makeStrip(title: "Manual drive", backgroundColor: .systemBrown)
  private var forwardScroll = true

  override var becomesScrollViewDelegate: Bool { true }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual Observation"
    addIntro(
      title: "observesAutomatically = false",
      body: "Scroll events are forwarded via fk_handleStickyScroll only while forwarding is enabled. Disable forwarding to freeze sticky geometry mid-scroll."
    )
    contentStack.addArrangedSubview(strip)
    addFillerBlocks()

    var configuration = FKStickyConfiguration.default
    configuration.observesAutomatically = false
    let engine = scrollView.fk_stickyEngine
    engine.configuration = configuration
    engine.addTarget(id: "manual", view: strip) { [weak self] progress in
      self?.updateStatus("manual → \(progress.state.rawValue) forward=\(self?.forwardScroll == true)")
    }

    addActions([
      FKStickyExampleUI.makeButton("Toggle scroll forwarding") { [weak self] in
        guard let self else { return }
        self.forwardScroll.toggle()
        self.updateStatus("forwardScroll=\(self.forwardScroll)")
      },
      FKStickyExampleUI.makeButton("Call handleScroll() once") { [weak self] in
        self?.scrollView.fk_stickyEngine.handleScroll()
      },
      FKStickyExampleUI.makeButton("startObserving() (auto KVO)") { [weak self] in
        self?.scrollView.fk_stickyEngine.startObserving()
        self?.updateStatus("observesAutomatically=true")
      },
      FKStickyExampleUI.makeButton("stopObserving()") { [weak self] in
        self?.scrollView.fk_stickyEngine.stopObserving()
        self?.forwardScroll = true
        self?.updateStatus("observesAutomatically=false; forwarding on")
      },
    ])
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard forwardScroll else { return }
    scrollView.fk_handleStickyScroll()
  }
}
