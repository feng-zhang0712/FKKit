import FKCoreKit
import UIKit

/// B6 — app icon badge helpers.
final class FKLocalNotificationExampleBadgeViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B6 Badge"

    addInfoLabel(
      "setBadgeCount uses UNUserNotificationCenter.setBadgeCount on iOS 16+ and UIApplication.applicationIconBadgeNumber on iOS 15."
    )

    addActionButton("setBadgeCount(3)") { [weak self] in
      self?.runTask("badge.set") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.setBadgeCount(3)
        self?.appendLog("Badge set to 3")
      }
    }

    addActionButton("clearBadge()") { [weak self] in
      self?.runTask("badge.clear") {
        try await FKLocalNotificationExampleSupport.manager.clearBadge()
        self?.appendLog("Badge cleared")
      }
    }

    addActionButton("Schedule notification with per-request badge: 5") { [weak self] in
      self?.runTask("badge.content") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("badge-content"),
            content: FKLocalNotificationContent(
              title: "Badge on delivery",
              body: "content.badge applies when the notification fires.",
              badge: 5
            ),
            trigger: .timeInterval(5, repeats: false)
          )
        )
      }
    }

    addActionButton("pendingRequests().count (64-item system limit)") { [weak self] in
      self?.runTask("pending.count") {
        let count = await FKLocalNotificationExampleSupport.manager.pendingRequests().count
        self?.appendLog("pending = \(count) — iOS silently drops beyond ~64 pending local notifications")
      }
    }

    addClearLogButton()
  }
}
