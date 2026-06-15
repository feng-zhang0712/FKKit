import FKCoreKit
import UIKit

/// B1 — permission pre-prompt, FKPermissions request, and scheduling gate.
final class FKLocalNotificationExamplePermissionGateViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B1 Permission Gate"

    addInfoLabel(
      """
      FKLocalNotificationManager never calls requestAuthorization directly.
      Integrators must grant access through FKPermissions before schedule(_:).
      """
    )

    addSectionHeading("Inspect without prompting")
    addActionButton("canScheduleNotifications()") { [weak self] in
      self?.runTask("canSchedule") {
        let allowed = await FKLocalNotificationExampleSupport.manager.canScheduleNotifications()
        self?.appendLog("canScheduleNotifications → \(allowed)")
      }
    }

    addActionButton("FKPermissions.status(for: .notifications)") { [weak self] in
      self?.runTask("status") {
        let status = await FKPermissions.shared.status(for: .notifications)
        self?.appendLog("notification status → \(status)")
      }
    }

    addSectionHeading("Request permission")
    addActionButton("Request with FKPermissionPrePrompt") { [weak self] in
      self?.runTask("request") {
        let granted = await FKLocalNotificationExampleSupport.ensureSchedulingAllowed { self?.appendLog($0) }
        self?.appendLog("ready to schedule → \(granted)")
      }
    }

    addSectionHeading("Schedule after grant")
    addActionButton("Schedule 5s reminder (after permission)") { [weak self] in
      self?.runTask("schedule") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }
        let request = FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier("permission-gate"),
          content: FKLocalNotificationContent(
            title: "Permission granted",
            body: "Scheduling works after FKPermissions granted access."
          ),
          trigger: .timeInterval(5, repeats: false)
        )
        try await FKLocalNotificationExampleSupport.manager.schedule(request)
        self?.appendLog("Scheduled id=\(request.identifier)")
      }
    }

    addActionButton("Schedule while denied → expect .notAuthorized") { [weak self] in
      self?.runTask("schedule.denied") {
        let status = await FKPermissions.shared.status(for: .notifications)
        guard status == .denied || status == .restricted else {
          self?.appendLog("Skip: status is \(status). Deny notifications in Settings to exercise this path.")
          return
        }
        try await FKLocalNotificationExampleSupport.manager.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("denied-probe"),
            content: FKLocalNotificationContent(title: "Should fail", body: "No permission"),
            trigger: .immediate
          )
        )
      }
    }

    addClearLogButton()
  }
}
