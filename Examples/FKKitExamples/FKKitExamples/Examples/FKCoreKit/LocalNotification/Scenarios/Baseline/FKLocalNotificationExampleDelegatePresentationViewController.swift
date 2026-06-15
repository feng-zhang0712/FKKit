import FKCoreKit
import UIKit

/// Foreground presentation options via installDelegate(presentation:).
final class FKLocalNotificationExampleDelegatePresentationViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Foreground Presentation"

    addInfoLabel(
      "Tune FKLocalNotificationPresentationOptions then schedule an immediate notification while staying in the foreground."
    )

    addSectionHeading("Presentation presets")
    addActionButton("installDelegate — banner + list + sound (standard)") { [weak self] in
      FKLocalNotificationExampleSupport.manager.installDelegate(presentation: .standard)
      self?.appendLog("presentation = [.banner, .list, .sound]")
    }

    addActionButton("installDelegate — banner only (silent)") { [weak self] in
      FKLocalNotificationExampleSupport.manager.installDelegate(presentation: [.banner])
      self?.appendLog("presentation = [.banner]")
    }

    addActionButton("installDelegate — list + badge (no banner/sound)") { [weak self] in
      FKLocalNotificationExampleSupport.manager.installDelegate(presentation: [.list, .badge])
      self?.appendLog("presentation = [.list, .badge]")
    }

    addSectionHeading("Deliver while foreground")
    addActionButton("Schedule immediate notification") { [weak self] in
      self?.runTask("immediate") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("foreground-preview"),
            content: FKLocalNotificationContent(
              title: "Foreground preview",
              body: "Observe banner/list/sound behavior with current presentation options.",
              badge: 2
            ),
            trigger: .immediate
          )
        )
      }
    }

    addClearLogButton()
  }
}
