import FKUIKit
import UIKit

final class FKAvatarExamplePresenceBadgeViewController: FKAvatarExampleScrollViewController {

  private let avatar = FKAvatar()
  private let logLabel = FKAvatarExampleSupport.eventLogLabel()
  private var presenceTimer: Timer?

  private let states: [FKPresenceState] = [.online, .away, .busy, .offline]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presence & badge"

    var config = FKAvatarConfiguration()
    config.layout.size = .l
    config.showsPresenceIndicator = true
    config.presenceState = .online
    avatar.configuration = config
    avatar.displayName = "Alex Morgan"
    avatar.setImageURL(FKAvatarExampleSupport.avatarURL(id: 64, size: 160), placeholder: nil)

    avatar.fk_badge.showCount(3, animated: true, animation: .pop())
    avatar.fk_badge.anchor = .topTrailing

    let box = FKAvatarExampleSupport.sectionContainer(title: "Presence + FKBadge")
    box.addArrangedSubview(FKAvatarExampleSupport.caption(
      "Presence attaches at the bottom-trailing corner (RTL-aware). Unread counts use FKBadgeController via UIView.fk_badge — not drawn inside FKAvatar."
    ))
    box.addArrangedSubview(FKAvatarExampleSupport.embedAvatar(avatar))
    box.addArrangedSubview(logLabel)

    let cycle = UIButton(type: .system)
    cycle.setTitle("Cycle presenceState", for: .normal)
    cycle.addAction(UIAction { [weak self] _ in self?.cyclePresence() }, for: .touchUpInside)

    let auto = UIButton(type: .system)
    auto.setTitle("Start auto cycle (3s)", for: .normal)
    auto.addAction(UIAction { [weak self] _ in self?.toggleAutoCycle(button: auto) }, for: .touchUpInside)

    let badgeStepper = UIStepper()
    badgeStepper.minimumValue = 0
    badgeStepper.maximumValue = 120
    badgeStepper.value = 3
    badgeStepper.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let value = Int(badgeStepper.value)
      if value == 0 {
        self.avatar.fk_clearBadge(animated: true)
      } else {
        self.avatar.fk_showBadgeCount(value, animated: true, animation: .pop())
      }
      self.appendLog("Badge count → \(value)")
    }, for: .valueChanged)

    box.addArrangedSubview(cycle)
    box.addArrangedSubview(auto)
    box.addArrangedSubview(FKAvatarExampleSupport.labeledRow(title: "Badge count", control: badgeStepper))

    contentStack.addArrangedSubview(box)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    presenceTimer?.invalidate()
    presenceTimer = nil
  }

  private var stateIndex = 0

  private func cyclePresence() {
    stateIndex = (stateIndex + 1) % states.count
    let next = states[stateIndex]
    avatar.presenceState = next
    appendLog("presenceState → \(describe(next))")
  }

  private func toggleAutoCycle(button: UIButton) {
    if presenceTimer != nil {
      presenceTimer?.invalidate()
      presenceTimer = nil
      button.setTitle("Start auto cycle (3s)", for: .normal)
      appendLog("Auto cycle stopped")
      return
    }
    button.setTitle("Stop auto cycle", for: .normal)
    presenceTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.cyclePresence()
      }
    }
    appendLog("Auto cycle started")
  }

  private func appendLog(_ line: String) {
    logLabel.text = line + "\n" + (logLabel.text ?? "")
  }

  private func describe(_ state: FKPresenceState) -> String {
    switch state {
    case .online: "online"
    case .offline: "offline"
    case .busy: "busy"
    case .away: "away"
    case .custom(let custom): "custom(\(custom.identifier))"
    }
  }
}
