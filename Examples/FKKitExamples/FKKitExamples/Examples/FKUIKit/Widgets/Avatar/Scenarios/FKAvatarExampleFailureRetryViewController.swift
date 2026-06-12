import FKUIKit
import UIKit

final class FKAvatarExampleFailureRetryViewController: FKAvatarExampleScrollViewController {

  private let avatar = FKAvatar()
  private let logLabel = FKAvatarExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Failure & retry"

    var config = FKAvatarConfiguration()
    config.layout.size = .l
    config.interaction.retriesOnFailure = true
    avatar.configuration = config
    avatar.displayName = "Retry demo"
    avatar.addAction(UIAction { [weak self] _ in
      self?.appendLog("Avatar tapped (retry on failure)")
    }, for: .touchUpInside)

    let box = FKAvatarExampleSupport.sectionContainer(title: "Tap to retry")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "Loads a URL that returns HTTP 404. Tap the avatar while in failed state to call FKImageView.retry(). VoiceOver announces failure and retry hint."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    box.addArrangedSubview(logLabel)

    let trigger = UIButton(type: .system)
    trigger.setTitle("Trigger 404 load", for: .normal)
    trigger.addAction(UIAction { [weak self] _ in
      self?.avatar.setImageURL(FKAvatarExampleSupport.brokenURL, placeholder: nil)
      self?.appendLog("Loading broken URL…")
    }, for: .touchUpInside)
    box.addArrangedSubview(trigger)

    contentStack.addArrangedSubview(box)
  }

  private func appendLog(_ line: String) {
    let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    logLabel.text = "[\(stamp)] \(line)\n" + (logLabel.text ?? "")
  }
}
