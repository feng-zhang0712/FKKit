import UIKit
import FKUIKit

final class FKActionSheetExampleLoadingContentViewController: FKActionSheetExampleBaseViewController {
  private weak var loadingSheet: FKActionSheet?
  private var fetchTask: Task<Void, Never>?
  private var nextFetchShouldFail = false
  private var lastLoadingPreferredHeight: CGFloat = 196

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loading Content"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Standard loading → fetch") { [weak self] in
      self?.nextFetchShouldFail = false
      self?.presentStandardLoadingSheet()
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Standard loading → fetch (fails)") { [weak self] in
      self?.nextFetchShouldFail = true
      self?.presentStandardLoadingSheet()
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Spinner only") { [weak self] in
      self?.nextFetchShouldFail = false
      self?.presentSpinnerOnlyLoadingSheet()
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Title only (no spinner)") { [weak self] in
      self?.nextFetchShouldFail = false
      self?.presentTitleOnlyLoadingSheet()
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Custom loading view") { [weak self] in
      self?.nextFetchShouldFail = false
      self?.presentCustomLoadingSheet()
    })

    let centered = UIStackView()
    centered.axis = .vertical
    centered.spacing = 8
    centered.addArrangedSubview(FKActionSheetExampleUI.button("Centered card loading → fetch") { [weak self] in
      self?.nextFetchShouldFail = false
      self?.presentCenteredLoadingSheet()
    })
    centered.addArrangedSubview(FKActionSheetExampleUI.button("Centered loading → fetch (fails)") { [weak self] in
      self?.nextFetchShouldFail = true
      self?.presentCenteredLoadingSheet()
    })

    body.addArrangedSubview(FKActionSheetExampleUI.button("Simulate fetch success") { [weak self] in
      self?.finishSimulatedFetch(succeeded: true)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Simulate fetch failure") { [weak self] in
      self?.finishSimulatedFetch(succeeded: false)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Dismiss sheet") { [weak self] in
      self?.loadingSheet?.dismiss(reason: .programmatic, animated: true)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Deferred action content",
        description: "Success uses finishLoading. Failure stays in loading mode with a centered FKEmptyStateView (Retry restores the spinner without dismissing). Cancel fetch tasks in didDismiss.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Centered presentation",
        description: "Same loading flow with presentation: .centered — floating card on a dimmed backdrop.",
        body: centered
      )
    )
    addClearLogButton()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    cancelFetchTask()
  }

  private func presentStandardLoadingSheet() {
    fetchTask?.cancel()
    let cancel = FKActionSheetExamplePlaybook.makeCancelAction()
    var config = FKActionSheetConfiguration.loading(
      .standard(
        FKActionSheetStandardLoadingContent(
          title: "Loading options",
          message: "Fetching share targets from the server…"
        )
      ),
      preferredPanelHeight: 196,
      cancelAction: cancel
    )
    attachFetchLifecycle(to: &config)

    guard let sheet = presentLoadingSheet(config, logLabel: "Presented loading sheet (standard)") else { return }
    scheduleSimulatedFetch(on: sheet, delaySeconds: 2.5, shouldFail: nextFetchShouldFail)
  }

  private func presentSpinnerOnlyLoadingSheet() {
    let config = makeLoadingConfiguration(
      content: .standard(FKActionSheetStandardLoadingContent(showsActivityIndicator: true)),
      preferredPanelHeight: 140
    )
    guard let sheet = presentLoadingSheet(config, logLabel: "Presented spinner-only loading") else { return }
    scheduleSimulatedFetch(on: sheet, delaySeconds: 2.5, shouldFail: nextFetchShouldFail)
  }

  private func presentTitleOnlyLoadingSheet() {
    let config = makeLoadingConfiguration(
      content: .standard(
        FKActionSheetStandardLoadingContent(
          showsActivityIndicator: false,
          title: "Loading options",
          message: "Fetching share targets from the server…"
        )
      ),
      preferredPanelHeight: 140
    )
    guard let sheet = presentLoadingSheet(config, logLabel: "Presented title-only loading") else { return }
    scheduleSimulatedFetch(on: sheet, delaySeconds: 2.5, shouldFail: nextFetchShouldFail)
  }

  private func presentCenteredLoadingSheet() {
    fetchTask?.cancel()
    let config = makeLoadingConfiguration(
      content: .standard(
        FKActionSheetStandardLoadingContent(
          title: "Loading options",
          message: "Centered card while fetching…"
        )
      ),
      preferredPanelHeight: 180,
      presentation: FKActionSheetExamplePlaybook.centeredPresentation(),
      appearancePreset: .card
    )
    guard let sheet = presentLoadingSheet(config, logLabel: "Presented centered loading sheet") else { return }
    scheduleSimulatedFetch(on: sheet, delaySeconds: 2.5, shouldFail: nextFetchShouldFail)
  }

  private func presentCustomLoadingSheet() {
    fetchTask?.cancel()
    let custom = FKActionSheetCustomLoadingContent(
      accessibilityLabel: "Custom loading",
      provider: .init { _ in
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        let symbol = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath"))
        symbol.tintColor = .secondaryLabel
        symbol.contentMode = .scaleAspectFit
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title2)
        symbol.setContentHuggingPriority(.required, for: .vertical)
        symbol.setContentHuggingPriority(.required, for: .horizontal)
        symbol.setContentCompressionResistancePriority(.required, for: .vertical)
        symbol.setContentCompressionResistancePriority(.required, for: .horizontal)
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "Custom loading view"
        stack.addArrangedSubview(symbol)
        stack.addArrangedSubview(label)
        return stack
      }
    )

    let config = makeLoadingConfiguration(
      content: .custom(custom),
      preferredPanelHeight: 160
    )
    guard let sheet = presentLoadingSheet(config, logLabel: "Presented loading sheet (custom)") else { return }
    scheduleSimulatedFetch(on: sheet, delaySeconds: 2, shouldFail: nextFetchShouldFail)
  }

  private func makeLoadingConfiguration(
    content: FKActionSheetLoadingContent,
    preferredPanelHeight: CGFloat,
    presentation: FKActionSheetPresentationConfiguration = .default,
    appearancePreset: FKActionSheetAppearancePreset? = nil
  ) -> FKActionSheetConfiguration {
    var config = FKActionSheetConfiguration.loading(
      content,
      preferredPanelHeight: preferredPanelHeight,
      cancelAction: FKActionSheetExamplePlaybook.makeCancelAction(),
      appearancePreset: appearancePreset,
      presentation: presentation
    )
    attachFetchLifecycle(to: &config)
    return config
  }

  /// Starts the simulated request when the sheet finishes presenting (alternative to scheduling after `present`).
  private func attachFetchLifecycle(to config: inout FKActionSheetConfiguration) {
    config = FKActionSheetExamplePlaybook.withEventLogging(config)
    let baseDidPresent = config.hooks.didPresent
    let baseDidDismiss = config.hooks.didDismiss
    config.hooks.didPresent = {
      baseDidPresent?()
      FKActionSheetExamplePlaybook.log("didPresent → fetch could start here")
    }
    config.hooks.didDismiss = { [weak self] reason in
      baseDidDismiss?(reason)
      self?.cancelFetchTask()
      FKActionSheetExamplePlaybook.log("didDismiss → fetch task cancelled")
    }
  }

  @discardableResult
  private func presentLoadingSheet(
    _ config: FKActionSheetConfiguration,
    logLabel: String
  ) -> FKActionSheet? {
    fetchTask?.cancel()
    do {
      let sheet = try FKActionSheet(configuration: config)
      try sheet.present(from: self)
      loadingSheet = sheet
      lastLoadingPreferredHeight = config.loadingConfiguration?.preferredPanelHeight ?? 196
      FKActionSheetExamplePlaybook.log(logLabel)
      return sheet
    } catch {
      FKActionSheetExamplePlaybook.log("Present failed: \(error)")
      return nil
    }
  }

  private func scheduleSimulatedFetch(
    on sheet: FKActionSheet,
    delaySeconds: TimeInterval,
    shouldFail: Bool
  ) {
    fetchTask?.cancel()
    fetchTask = Task { @MainActor [weak self] in
      let nanoseconds = UInt64(delaySeconds * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanoseconds)
      guard !Task.isCancelled else { return }
      self?.finishSimulatedFetch(succeeded: !shouldFail)
    }
  }

  private func finishSimulatedFetch(succeeded: Bool) {
    guard let sheet = loadingSheet, sheet.isPresented else {
      FKActionSheetExamplePlaybook.log("No presented loading sheet")
      return
    }

    if succeeded {
      applySimulatedSuccess(to: sheet)
    } else {
      applySimulatedFailure(to: sheet)
    }
  }

  private func applySimulatedSuccess(to sheet: FKActionSheet) {
    let share = FKActionSheetAction(title: "Messages", symbolName: "message.fill") {
      FKActionSheetExamplePlaybook.log("Messages")
    }
    let mail = FKActionSheetAction(title: "Mail", symbolName: "envelope.fill") {
      FKActionSheetExamplePlaybook.log("Mail")
    }

    if sheet.finishLoading(
      sections: [FKActionSheetSection(actions: [share, mail])],
      header: .text(
        FKActionSheetHeader(title: "Share photo", message: "Loaded from simulated network")
      )
    ) {
      FKActionSheetExamplePlaybook.log("finishLoading(sections:header:) → hooks/appearance preserved")
    } else {
      FKActionSheetExamplePlaybook.log("finishLoading failed validation")
    }
  }

  private func applySimulatedFailure(to sheet: FKActionSheet) {
    let failure = FKActionSheetExampleLoadingSupport.failureLoadingConfiguration(
      preferredPanelHeight: lastLoadingPreferredHeight,
      onRetry: { [weak self] in
        self?.retryAfterFailure(on: sheet)
      }
    )
    if sheet.setLoading(failure) {
      FKActionSheetExamplePlaybook.log("setLoading → EmptyState failure (sheet stays open)")
    }
  }

  private func retryAfterFailure(on sheet: FKActionSheet) {
    guard loadingSheet?.isPresented == true else { return }
    FKActionSheetExamplePlaybook.log("Retry → restore standard loading")
    guard sheet.setLoading(
      FKActionSheetExampleLoadingSupport.standardLoadingConfiguration(
        preferredPanelHeight: lastLoadingPreferredHeight
      )
    ) else { return }
    nextFetchShouldFail = false
    scheduleSimulatedFetch(on: sheet, delaySeconds: 1.5, shouldFail: false)
  }

  private func cancelFetchTask() {
    fetchTask?.cancel()
    fetchTask = nil
  }
}
