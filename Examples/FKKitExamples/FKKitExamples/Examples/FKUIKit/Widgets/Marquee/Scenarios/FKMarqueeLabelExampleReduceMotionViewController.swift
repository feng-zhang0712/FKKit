import FKUIKit
import UIKit

final class FKMarqueeLabelExampleReduceMotionViewController: FKMarqueeLabelExampleScrollViewController {

  private let marquee = FKMarqueeLabel(text: FKMarqueeLabelExampleSupport.sampleLongText)
  private let statusLabel = FKMarqueeLabelExampleSupport.statusLabel(initial: "")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reduce Motion"

    var config = FKMarqueeLabelConfiguration()
    config.animation.respectsReducedMotion = true
    config.animation.delay = 0.25
    marquee.configuration = config

    NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.refreshStatus()
      }
    }

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "respectsReducedMotion")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "When Reduce Motion is on, scrolling stops and the label shows a static tail-truncated line. VoiceOver still reads the full text via accessibilityLabel."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    box.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(box)

    refreshStatus()
  }

  private func refreshStatus() {
    let enabled = UIAccessibility.isReduceMotionEnabled
    statusLabel.text = """
      Reduce Motion: \(enabled ? "ON" : "OFF")
      Toggle in Settings → Accessibility → Motion → Reduce Motion, then return here.
      """
  }
}
