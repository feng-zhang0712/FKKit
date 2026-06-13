import FKUIKit
import UIKit

final class FKMarqueeLabelExampleBackgroundPauseViewController: FKMarqueeLabelExampleScrollViewController {

  private let marquee = FKMarqueeLabel(text: FKMarqueeLabelExampleSupport.sampleLongText)
  private let statusLabel = FKMarqueeLabelExampleSupport.statusLabel(initial: "App state: active (foreground)")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Background pause"

    marquee.configuration.animation.delay = 0.25

    let center = NotificationCenter.default
    center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.statusLabel.text = "App state: background — DisplayLink stopped. Scrolling resumes on return."
      }
    }
    center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.statusLabel.text = "App state: foreground — scrolling resumed after start delay (if any)."
      }
    }

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "Lifecycle")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "FKMarqueeLabel pauses the scroll driver when the app enters background or the view leaves the window hierarchy. Switch apps to verify CPU usage stops."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    box.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(box)
  }
}
