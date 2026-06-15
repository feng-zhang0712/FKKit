import FKCoreKit
import UIKit

/// B5 — replace-by-id, batch operations, pending/delivered queries, removal APIs.
final class FKLocalNotificationExampleCancelReplaceViewController: FKLocalNotificationExampleBaseViewController {
  private let replaceID = FKLocalNotificationExampleSupport.identifier("replace-demo")
  private let batchIDs: [String] = (1 ... 3).map { FKLocalNotificationExampleSupport.identifier("batch-\($0)") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cancel & Query"

    addInfoLabel("Demonstrates identifier replace semantics, batch schedule/cancel, and query/remove APIs.")

    addSectionHeading("Replace by identifier")
    addActionButton("Schedule replace-demo (version A, 30s)") { [weak self] in
      self?.scheduleReplace(version: "A", delay: 30)
    }
    addActionButton("Replace same id (version B, 12s)") { [weak self] in
      self?.scheduleReplace(version: "B", delay: 12)
    }

    addSectionHeading("Batch schedule & cancel")
    addActionButton("schedule([batch-1, batch-2, batch-3])") { [weak self] in
      self?.runTask("batch.schedule") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        let requests = (1 ... 3).map { index in
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("batch-\(index)"),
            content: FKLocalNotificationContent(
              title: "Batch \(index)",
              body: "Scheduled via schedule([_]) API."
            ),
            trigger: .timeInterval(TimeInterval(20 + index * 5), repeats: false)
          )
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(requests)
        self?.appendLog("Batch scheduled \(requests.count) requests")
      }
    }

    addActionButton("cancelPending(withIdentifiers: batch IDs)") { [weak self] in
      guard let self else { return }
      self.runTask("batch.cancel") {
        await FKLocalNotificationExampleSupport.manager.cancelPending(withIdentifiers: self.batchIDs)
      }
    }

    addActionButton("cancelAllPending()") { [weak self] in
      self?.runTask("cancel.all") {
        await FKLocalNotificationExampleSupport.manager.cancelAllPending()
      }
    }

    addSectionHeading("Query")
    addActionButton("pendingRequests()") { [weak self] in
      self?.runTask("pending") {
        let items = await FKLocalNotificationExampleSupport.manager.pendingRequests()
        self?.appendLog("pending count = \(items.count)")
        items.forEach { self?.appendLog("  \($0.identifier): \($0.content.title)") }
      }
    }

    addActionButton("deliveredNotifications()") { [weak self] in
      self?.runTask("delivered") {
        let items = await FKLocalNotificationExampleSupport.manager.deliveredNotifications()
        self?.appendLog("delivered count = \(items.count)")
        items.forEach { self?.appendLog("  \($0.identifier) @ \($0.deliveryDate?.description ?? "nil")") }
      }
    }

    addSectionHeading("Remove delivered")
    addActionButton("Schedule immediate (for delivered list)") { [weak self] in
      self?.runTask("deliver") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("delivered-cleanup"),
            content: FKLocalNotificationContent(title: "Delivered sample", body: "Remove from Notification Center."),
            trigger: .immediate
          )
        )
      }
    }

    addActionButton("removeDelivered(withIdentifier:)") { [weak self] in
      self?.runTask("remove.one") {
        await FKLocalNotificationExampleSupport.manager.removeDelivered(
          withIdentifier: FKLocalNotificationExampleSupport.identifier("delivered-cleanup")
        )
      }
    }

    addActionButton("removeDelivered(withIdentifiers:) + removeAllDelivered()") { [weak self] in
      self?.runTask("remove.batch") {
        await FKLocalNotificationExampleSupport.manager.removeDelivered(
          withIdentifiers: [FKLocalNotificationExampleSupport.identifier("delivered-cleanup")]
        )
        await FKLocalNotificationExampleSupport.manager.removeAllDelivered()
      }
    }

    addClearLogButton()
  }

  private func scheduleReplace(version: String, delay: TimeInterval) {
    runTask("replace.\(version)") { [self] in
      guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self.appendLog($0) }) else {
        throw FKLocalNotificationError.notAuthorized
      }
      try await FKLocalNotificationExampleSupport.manager.schedule(
        FKLocalNotificationRequest(
          identifier: self.replaceID,
          content: FKLocalNotificationContent(
            title: "Replace demo \(version)",
            body: "Same identifier replaces the pending request."
          ),
          trigger: .timeInterval(delay, repeats: false)
        )
      )
      let pending = await FKLocalNotificationExampleSupport.manager.pendingRequests()
      let match = pending.first { $0.identifier == self.replaceID }
      self.appendLog("pending replace-demo title → \(match?.content.title ?? "not found")")
    }
  }
}
