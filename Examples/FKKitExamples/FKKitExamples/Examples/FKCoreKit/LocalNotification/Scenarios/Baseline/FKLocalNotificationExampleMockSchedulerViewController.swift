import FKCoreKit
import UIKit

/// B8 — FKMockLocalNotificationScheduler, Pluggable injection, validation errors.
final class FKLocalNotificationExampleMockSchedulerViewController: FKLocalNotificationExampleBaseViewController {
  private let mock = FKMockLocalNotificationScheduler()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Mock & Pluggable"

    addInfoLabel(
      "FKMockLocalNotificationScheduler exercises scheduling logic without UNUserNotificationCenter or system permission prompts."
    )

    addSectionHeading("In-memory scheduler")
    addActionButton("Mock schedule + inspect scheduled") { [weak self] in
      guard let self else { return }
      self.runTask("mock.schedule") {
        try await self.mock.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("mock-1"),
            content: FKLocalNotificationContent(title: "Mock", body: "In-memory only"),
            trigger: .timeInterval(10, repeats: false)
          )
        )
        self.appendLog("mock.scheduled.count = \(self.mock.scheduled.count)")
        self.mock.scheduled.forEach { self.appendLog("  \($0.identifier)") }
      }
    }

    addActionButton("simulateDelivery + simulateResponse") { [weak self] in
      guard let self else { return }
      let id = FKLocalNotificationExampleSupport.identifier("mock-1")
      self.mock.responseHandler = { response in
        Task { @MainActor in
          self.appendLog("mock response — action=\(response.actionIdentifier)")
        }
      }
      self.mock.simulateDelivery(identifier: id)
      self.mock.simulateResponse(requestIdentifier: id)
    }

    addActionButton("Mock cancelPending + authorizationGranted = false") { [weak self] in
      guard let self else { return }
      self.runTask("mock.cancel") {
        await self.mock.cancelPending(withIdentifier: FKLocalNotificationExampleSupport.identifier("mock-1"))
        self.mock.authorizationGranted = false
        do {
          try await self.mock.schedule(
            FKLocalNotificationRequest(
              identifier: "should-fail",
              content: FKLocalNotificationContent(title: "Denied", body: "No auth"),
              trigger: .immediate
            )
          )
        } catch {
          self.appendLog("expected failure: \(FKLocalNotificationExampleSupport.formatError(error))")
        }
        self.mock.authorizationGranted = true
      }
    }

    addSectionHeading("FKLocalNotificationScheduling (Pluggable)")
    addActionButton("Inject mock via protocol type") { [weak self] in
      guard let self else { return }
      let scheduler: any FKLocalNotificationScheduling = self.mock
      self.runTask("pluggable") {
        try await scheduler.schedule(
          FKLocalNotificationRequest(
            identifier: FKLocalNotificationExampleSupport.identifier("pluggable"),
            content: FKLocalNotificationContent(title: "Pluggable", body: "Protocol boundary"),
            trigger: .immediate
          )
        )
        self.appendLog("Scheduled through `any FKLocalNotificationScheduling`")
      }
    }

    addSectionHeading("Validation errors")
    addActionButton("invalidTrigger — repeating interval < 60s") { [weak self] in
      guard let self else { return }
      self.runTask("invalid.trigger") {
        try await self.mock.schedule(
          FKLocalNotificationRequest(
            identifier: "bad-trigger",
            content: FKLocalNotificationContent(title: "Bad", body: "Trigger"),
            trigger: .timeInterval(30, repeats: true)
          )
        )
      }
    }

    addActionButton("invalidContent — empty title and body") { [weak self] in
      guard let self else { return }
      self.runTask("invalid.content") {
        try await self.mock.schedule(
          FKLocalNotificationRequest(
            identifier: "bad-content",
            content: FKLocalNotificationContent(title: "  ", body: ""),
            trigger: .immediate
          )
        )
      }
    }

    addActionButton("invalidContent — empty identifier") { [weak self] in
      guard let self else { return }
      self.runTask("invalid.id") {
        try await self.mock.schedule(
          FKLocalNotificationRequest(
            identifier: "   ",
            content: FKLocalNotificationContent(title: "ID", body: "Missing identifier"),
            trigger: .immediate
          )
        )
      }
    }

    addSectionHeading("FKLocalNotificationError catalog (FKI18n)")
    addActionButton("Print all LocalizedError descriptions") { [weak self] in
      FKLocalNotificationExampleSupport.sampleErrors.forEach { error in
        self?.appendLog("\(error) → \(error.localizedDescription)")
      }
    }

    addClearLogButton()
  }
}
