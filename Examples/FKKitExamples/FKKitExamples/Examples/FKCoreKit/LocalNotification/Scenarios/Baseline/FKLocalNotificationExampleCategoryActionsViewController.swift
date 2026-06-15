import FKCoreKit
import UIKit

/// B4 — category registration, custom actions, and response handling.
final class FKLocalNotificationExampleCategoryActionsViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B4 Category Actions"

    FKLocalNotificationExampleSupport.installDelegate { [weak self] in self?.appendLog($0) }
    FKLocalNotificationExampleSupport.wireResponseHandler { [weak self] in self?.appendLog($0) }

    addInfoLabel(
      "Long-press the delivered notification (or pull down on lock screen) to reveal Mark Read and Snooze actions."
    )

    addActionButton("registerCategories (message category)") { [weak self] in
      self?.runTask("register") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.registerCategories([
          FKLocalNotificationExampleSupport.registerMessageCategory(),
        ])
        let ids = await FKLocalNotificationExampleSupport.manager.registeredCategoryIdentifiers()
        self?.appendLog("registeredCategoryIdentifiers → \(ids.sorted())")
      }
    }

    addActionButton("Schedule categorized notification (5s)") { [weak self] in
      self?.runTask("schedule") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.registerCategories([
          FKLocalNotificationExampleSupport.registerMessageCategory(),
        ])
        let request = FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier("category-message"),
          content: FKLocalNotificationContent(
            title: "New message",
            body: "Tap an action or open the notification."
          ),
          trigger: .timeInterval(5, repeats: false),
          categoryIdentifier: FKLocalNotificationExampleSupport.categoryIdentifier
        )
        try await FKLocalNotificationExampleSupport.manager.schedule(request)
      }
    }

    addActionButton("Schedule with unregistered category (debug warning only)") { [weak self] in
      self?.runTask("unregistered-category") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("missing-category"),
            content: FKLocalNotificationContent(title: "No actions", body: "Category not registered."),
            trigger: .timeInterval(6, repeats: false),
            categoryIdentifier: "fkkit.example.unregistered"
          )
        )
        self?.appendLog("Scheduled — check debug log for unregistered category warning")
      }
    }

    addClearLogButton()
  }
}
