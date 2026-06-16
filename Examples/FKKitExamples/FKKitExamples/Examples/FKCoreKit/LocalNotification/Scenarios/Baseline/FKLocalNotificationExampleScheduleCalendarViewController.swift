import FKCoreKit
import UIKit

/// B3 — calendar trigger with daily repeat and pending inspection.
final class FKLocalNotificationExampleScheduleCalendarViewController: FKLocalNotificationExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Calendar Daily"

    addInfoLabel(
      "Schedules a daily repeating notification at the next clock minute (local timezone). Use pendingRequests() to verify the entry."
    )

    addActionButton("Schedule daily calendar notification") { [weak self] in
      self?.runTask("calendar.daily") {
        guard await FKLocalNotificationExampleSupport.ensureSchedulingAllowed(log: { self?.appendLog($0) }) else {
          throw FKLocalNotificationError.notAuthorized
        }

        let fireDate = Date().addingTimeInterval(90)
        var components = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
        components.second = 0
        let calendarTrigger = FKLocalNotificationCalendarTrigger(
          dateComponents: components,
          timezone: .current
        )

        let request = FKLocalNotificationRequest(
          identifier: FKLocalNotificationExampleSupport.identifier("calendar-daily"),
          content: FKLocalNotificationContent(
            title: "Daily reminder",
            body: "Calendar trigger with repeats: true at \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))."
          ),
          trigger: .calendar(calendarTrigger, repeats: true)
        )
        try await FKLocalNotificationExampleSupport.manager.schedule(request)
        self?.appendLog("Daily calendar trigger registered in timezone \(calendarTrigger.timezone.identifier)")
      }
    }

    addActionButton("List pendingRequests()") { [weak self] in
      self?.runTask("pending") {
        let pending = await FKLocalNotificationExampleSupport.manager.pendingRequests()
        if pending.isEmpty {
          self?.appendLog("No pending notifications")
          return
        }
        for item in pending {
          self?.appendLog("• \(item.identifier) — \(item.triggerDescription)")
        }
      }
    }

    addActionButton("Cancel daily calendar demo") { [weak self] in
      self?.runTask("cancel") {
        await FKLocalNotificationExampleSupport.manager.cancelPending(
          withIdentifier: FKLocalNotificationExampleSupport.identifier("calendar-daily")
        )
      }
    }

    addClearLogButton()
  }
}
