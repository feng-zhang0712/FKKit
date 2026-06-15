import UIKit
import FKCoreKit

/// B8 — ``FKMockBackgroundTaskScheduler``, Pluggable protocols, validation errors, and configuration.
final class FKBackgroundTaskExampleMockAndPluggableViewController: FKBackgroundTaskExampleBaseViewController {
  private let mock = FKMockBackgroundTaskScheduler()
  private let mockID = "fkkit.example.mock.pluggable"

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "MockAndPluggable"

    addInfoLabel(
      "In-memory scheduler for unit tests and CI — no BGTaskScheduler or UIKit background task required."
    )

    addSectionHeading("FKBackgroundTaskScheduling")
    addActionButton("Setup mock + schedule via protocol") { [weak self] in
      guard let self else { return }
      self.runTask("pluggable schedule") {
        try self.mock.registerAppRefresh(identifier: self.mockID) { _ in true }
        try self.mock.installRegistrations([.init(identifier: self.mockID, kind: .appRefresh)])
        let scheduler: any FKBackgroundTaskScheduling = self.mock
        try await scheduler.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(
            identifier: self.mockID,
            earliestBeginDate: Date().addingTimeInterval(900)
          )
        )
        self.appendLog("scheduledRefresh count = \(self.mock.scheduledRefresh.count)")
        self.appendLog("First request: \(String(describing: self.mock.scheduledRefresh.first))")
      }
    }

    addActionButton("Schedule processing on mock") { [weak self] in
      guard let self else { return }
      let processingID = "fkkit.example.mock.processing"
      self.runTask("mock processing") {
        try self.mock.registerProcessing(identifier: processingID) { _ in true }
        try self.mock.installRegistrations([.init(identifier: processingID, kind: .processing)])
        try await self.mock.scheduleProcessing(
          FKBackgroundProcessingRequest(
            identifier: processingID,
            requiresNetworkConnectivity: true,
            requiresExternalPower: false
          )
        )
        self.appendLog("scheduledProcessing count = \(self.mock.scheduledProcessing.count)")
      }
    }

    addActionButton("cancelScheduledTask on mock") { [weak self] in
      guard let self else { return }
      self.runTask("mock cancel") {
        try await self.mock.cancelScheduledTask(withIdentifier: self.mockID)
        self.appendLog("scheduledRefresh after cancel = \(self.mock.scheduledRefresh.count)")
      }
    }

    addActionButton("simulateLaunch on mock") { [weak self] in
      guard let self else { return }
      self.runTask("simulateLaunch") {
        await self.mock.simulateLaunch(identifier: self.mockID)
        self.appendLog("simulateLaunch finished")
      }
    }

    addSectionHeading("Validation errors")
    addActionButton("duplicateRegistration") { [weak self] in
      guard let self else { return }
      self.runTask("duplicate") {
        try self.mock.registerAppRefresh(identifier: self.mockID) { _ in true }
      }
    }

    addActionButton("notInstalled (schedule before install)") { [weak self] in
      guard let self else { return }
      let fresh = FKMockBackgroundTaskScheduler()
      self.runTask("notInstalled") {
        try fresh.registerAppRefresh(identifier: "fkkit.example.fresh", handler: { _ in true })
        try await fresh.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(identifier: "fkkit.example.fresh")
        )
      }
    }

    addActionButton("unregisteredIdentifier") { [weak self] in
      guard let self else { return }
      try? self.mock.installRegistrations([])
      self.mock.markInstalled()
      self.runTask("unregistered") {
        try await self.mock.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(identifier: "fkkit.example.unknown")
        )
      }
    }

    addSectionHeading("FKBackgroundTaskError catalog (FKI18n)")
    addActionButton("Show localized error descriptions") { [weak self] in
      FKBackgroundTaskExampleSupport.sampleErrors.forEach { error in
        self?.appendLog("\(error) → \(error.localizedDescription)")
      }
    }

    addClearLogButton()
  }
}
