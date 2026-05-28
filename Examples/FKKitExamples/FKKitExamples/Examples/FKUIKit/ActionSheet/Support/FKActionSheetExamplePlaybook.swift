import UIKit
import FKUIKit

/// Shared presentation helpers for UIKit pages and the SwiftUI host.
enum FKActionSheetExamplePlaybook {
  static func log(_ message: String) {
    FKActionSheetExampleEventLog.shared.append(message)
  }

  @discardableResult
  static func present(
    _ configuration: FKActionSheetConfiguration,
    from presenter: UIViewController,
    logEvents: Bool = true
  ) -> FKActionSheet? {
    presentInstance(configuration, from: presenter, logEvents: logEvents)
  }

  /// Recommended integration: create a sheet, retain it, then present.
  @discardableResult
  static func presentInstance(
    _ configuration: FKActionSheetConfiguration,
    from presenter: UIViewController,
    logEvents: Bool = true
  ) -> FKActionSheet? {
    let config = logEvents ? withEventLogging(configuration) : configuration
    do {
      let sheet = try FKActionSheet(configuration: config)
      try sheet.present(from: presenter)
      log("init(configuration:) + present(from:)")
      return sheet
    } catch let error as FKActionSheetValidationError {
      log("Validation failed: \(error)")
      FKToast.show(error.exampleToastMessage, style: .error, kind: .toast)
      return nil
    } catch {
      log("Instance present failed: \(error)")
      FKToast.show("Could not present action sheet.", style: .error, kind: .toast)
      return nil
    }
  }

  static func withEventLogging(_ configuration: FKActionSheetConfiguration) -> FKActionSheetConfiguration {
    var config = configuration
    let base = config.hooks
    config.hooks = FKActionSheetLifecycleHooks(
      willPresent: {
        log("willPresent")
        base.willPresent?()
      },
      didPresent: {
        log("didPresent")
        base.didPresent?()
      },
      willDismiss: { reason in
        log("willDismiss(\(String(describing: reason)))")
        base.willDismiss?(reason)
      },
      didDismiss: { reason in
        log("didDismiss(\(String(describing: reason)))")
        base.didDismiss?(reason)
      },
      didSelect: { action in
        log("didSelect(\(action.title))")
        base.didSelect?(action)
      }
    )
    return config
  }

  static func makeCancelAction(title: String = "Cancel") -> FKActionSheetAction {
    FKActionSheetAction(title: title, style: .cancel)
  }

  // MARK: - Basics

  static func presentBasics(from presenter: UIViewController) {
    let share = FKActionSheetAction(title: "Share") { log("Share handler") }
    let delete = FKActionSheetAction(title: "Delete", style: .destructive) { log("Delete handler") }
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Photo", message: "Choose an action")),
      sections: [FKActionSheetSection(actions: [share, delete])],
      cancelAction: makeCancelAction()
    )
    _ = presentInstance(config, from: presenter)
  }

  static func presentInstanceAPI(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Instance API", message: "Retain the returned FKActionSheet for reload and dismiss.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "OK") { log("Instance API action") }])],
      cancelAction: makeCancelAction()
    )
    _ = presentInstance(config, from: presenter)
  }

  static func presentValidationFailure(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(sections: [])
    do {
      try FKActionSheet.validate(config)
      log("Unexpected: empty config validated")
    } catch {
      log("validate rejected: \(error)")
    }
  }

  // MARK: - Appearance

  static func presentAppearancePreset(_ preset: FKActionSheetAppearancePreset, from presenter: UIViewController) {
    let presetName: String = {
      switch preset {
      case .system: return "system"
      case .card: return "card"
      case .plain: return "plain"
      }
    }()
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Appearance", message: "\(presetName) preset")),
      sections: [
        FKActionSheetSection(
          title: "Options",
          actions: [
            FKActionSheetAction(title: "Primary action") { log("Primary") },
            FKActionSheetAction(title: "Secondary action") { log("Secondary") },
          ]
        ),
      ],
      cancelAction: makeCancelAction(),
      appearancePreset: preset
    )
    _ = present(config, from: presenter)
  }

  static func presentLeadingAlignment(from presenter: UIViewController) {
    var appearance = FKActionSheetAppearance.preset(.plain)
    appearance.rowAlignment = .leading
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Leading alignment")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Left aligned row", subtitle: "Subtitle follows leading edge") { log("Leading") },
        ]),
      ],
      cancelAction: makeCancelAction(),
      appearance: appearance
    )
    _ = present(config, from: presenter)
  }

  static func presentNoSeparators(from presenter: UIViewController) {
    var appearance = FKActionSheetAppearance.default
    appearance.separatorStyle = .none
    let config = FKActionSheetConfiguration(
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Flat group") { log("Flat") }])],
      cancelAction: makeCancelAction(),
      appearance: appearance
    )
    _ = present(config, from: presenter)
  }

  // MARK: - Symbols & states

  static func presentSymbolsAndSubtitles(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Share photo")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Messages", subtitle: "Send to contacts", symbolName: "message.fill") {
            log("Messages")
          },
          FKActionSheetAction(title: "Mail", subtitle: "Attach as file", symbolName: "envelope.fill") {
            log("Mail")
          },
        ]),
      ],
      cancelAction: makeCancelAction()
    )
    _ = present(config, from: presenter)
  }

  static func presentDisabledAndLoading(from presenter: UIViewController) -> FKActionSheet? {
    var loading = FKActionSheetAction(title: "Uploading…", symbolName: "arrow.up.circle")
    loading.isLoading = true
    loading.isEnabled = false
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Disabled and loading rows block taps.")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Available action") { log("Available") },
          FKActionSheetAction(title: "Disabled action", isEnabled: false) { log("Should not run") },
          loading,
        ]),
      ],
      cancelAction: makeCancelAction()
    )
    return present(config, from: presenter)
  }

  static func presentStayOpenAction(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(
            title: "Toggle setting",
            dismissesSheetWhenSelected: false
          ) { log("Stay-open action") },
        ]),
      ],
      cancelAction: makeCancelAction(),
      dismissesAfterActionSelection: true
    )
    _ = present(config, from: presenter)
  }

  // MARK: - Custom content

  static func presentCustomHeaderAndRow(from presenter: UIViewController) {
    struct Profile { let name: String; let role: String }

    let header = FKActionSheetCustomHeader(
      preferredHeight: 104,
      accessibilityLabel: "Profile header",
      provider: .init { _ in
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = .label
        avatar.contentMode = .scaleAspectFit
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let name = UILabel()
        name.font = .preferredFont(forTextStyle: .headline)
        name.text = "Alex Morgan"
        let role = UILabel()
        role.font = .preferredFont(forTextStyle: .subheadline)
        role.textColor = .secondaryLabel
        role.text = "Product design"
        stack.addArrangedSubview(avatar)
        stack.addArrangedSubview(name)
        stack.addArrangedSubview(role)
        return stack
      }
    )

    let profile = Profile(name: "Alex Morgan", role: "Product design")
    let custom = FKActionSheetAction.custom(
      metadata: FKActionSheetMetadata(storage: ["profile": profile]),
      actionHandler: { _ in log("Custom row selected") },
      build: { context in
        let profile = context.action.metadata?.value(Profile.self, forKey: "profile")
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.text = "View \(profile?.name ?? "profile")"
        return label
      }
    )

    let config = FKActionSheetConfiguration(
      customHeader: header,
      sections: [FKActionSheetSection(actions: [custom, FKActionSheetAction(title: "Standard row") { log("Standard") }])],
      cancelAction: makeCancelAction()
    )
    _ = present(config, from: presenter)
  }

  static func presentNonSelectableCustomRow(from presenter: UIViewController) {
    let banner = FKActionSheetAction.custom(
      reuseIdentifier: "FKActionSheetExampleBannerRow",
      preferredHeight: 56,
      isSelectable: false,
      build: { _ in
        let label = UILabel()
        label.text = "Non-selectable info banner"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.backgroundColor = .tertiarySystemFill
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
      }
    )
    let config = FKActionSheetConfiguration(
      sections: [
        FKActionSheetSection(actions: [
          banner,
          FKActionSheetAction(title: "Continue") { log("Continue") },
        ]),
      ],
      cancelAction: makeCancelAction()
    )
    _ = present(config, from: presenter)
  }

  // MARK: - Toggle

  static func presentToggleRows(from presenter: UIViewController) {
    let deleteAttachments = FKActionSheetAction.toggle(title: "Delete attachments", isOn: false) { isOn in
      log("Delete attachments = \(isOn)")
    }
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Send options", message: "Toggle rows keep the sheet open.")),
      sections: [FKActionSheetSection(actions: [deleteAttachments])],
      cancelAction: makeCancelAction(),
      dismissesAfterActionSelection: true
    )
    _ = present(config, from: presenter)
  }

  // MARK: - Handlers & lifecycle

  static func presentHandlerTiming(_ timing: FKActionSheetHandlerTiming, from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Handler timing: \(timing)")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Run handler") {
            log("Handler (\(timing))")
          },
        ]),
      ],
      cancelAction: makeCancelAction(),
      handlerTiming: timing
    )
    _ = present(config, from: presenter)
  }

  static func presentActionHandler(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Log action ID", actionHandler: { action in
            log("actionHandler id=\(action.id.uuidString.prefix(8))")
          }),
        ]),
      ],
      cancelAction: makeCancelAction()
    )
    _ = present(config, from: presenter)
  }

  static func presentWithHaptics(from presenter: UIViewController) {
    var config = FKActionSheetConfiguration(
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Haptic row") { log("Haptic row") }])],
      cancelAction: makeCancelAction()
    )
    config.haptics = FKActionSheetHapticsConfiguration(onActionSelection: true, impactStyle: .medium)
    _ = present(config, from: presenter)
  }

  static func presentDismissReasonsDemo(from presenter: UIViewController) {
    let destructive = FKActionSheetAction(title: "Delete", style: .destructive) { log("Delete tapped") }
    let config = FKActionSheetConfiguration(
      header: .text(
        FKActionSheetHeader(
          title: "Dismiss reasons",
          message: "Cancel → userCancel. Action → actionSelected. Backdrop → tapOutside (if enabled)."
        )
      ),
      sections: [FKActionSheetSection(actions: [destructive])],
      cancelAction: makeCancelAction(),
      presentation: {
        var configuration = FKActionSheetPresentationConfiguration.default
        configuration.allowsTapOutsideDismiss = true
        return configuration
      }()
    )
    _ = presentInstance(config, from: presenter, logEvents: true)
  }

  static func presentHooksDidSelect(from presenter: UIViewController) {
    var config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "hooks.didSelect fires on every row tap.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Select me") { log("actionHandler") }])],
      cancelAction: makeCancelAction()
    )
    let base = config.hooks
    config.hooks.didSelect = { (action: FKActionSheetAction) in
      log("hooks.didSelect(\(action.title))")
      base.didSelect?(action)
    }
    _ = present(config, from: presenter, logEvents: true)
  }

  // MARK: - Live updates

  static func presentForLiveReload(from presenter: UIViewController) -> FKActionSheet? {
    var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
    share.isLoading = false
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Use page buttons to reload or update rows.")),
      sections: [FKActionSheetSection(actions: [share])],
      cancelAction: makeCancelAction()
    )
    return presentInstance(config, from: presenter)
  }

  static func applyLiveReload(to sheet: FKActionSheet) {
    let share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
    let copy = FKActionSheetAction(title: "Copy", symbolName: "doc.on.doc")
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Reloaded with an extra action.")),
      sections: [FKActionSheetSection(actions: [share, copy])],
      cancelAction: makeCancelAction()
    )
    sheet.reload(configuration: config)
    log("reload(configuration:)")
  }

  static func applyLiveUpdateLoading(to sheet: FKActionSheet) {
    var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
    share.isLoading = true
    sheet.updateAction(share)
    log("updateAction → loading")
  }

  static func applyLiveUpdateReady(to sheet: FKActionSheet) {
    var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
    share.isLoading = false
    sheet.updateAction(share)
    log("updateAction → ready")
  }

  // MARK: - Centered presentation

  /// Builds ``FKActionSheetPresentationConfiguration/centered`` tuning for card-style sheets.
  static func centeredPresentation(
    allowsTapOutsideDismiss: Bool = true,
    backdropAlpha: CGFloat? = nil,
    maxPanelWidth: CGFloat? = nil,
    horizontalInset: CGFloat? = nil,
    maximumPanelHeight: CGFloat? = nil,
    cornerRadius: CGFloat? = nil
  ) -> FKActionSheetPresentationConfiguration {
    var presentation = FKActionSheetPresentationConfiguration.centered
    presentation.allowsTapOutsideDismiss = allowsTapOutsideDismiss
    if let backdropAlpha { presentation.backdropAlpha = backdropAlpha }
    if let maxPanelWidth { presentation.maxPanelWidth = maxPanelWidth }
    if let horizontalInset { presentation.horizontalInset = horizontalInset }
    if let maximumPanelHeight { presentation.maximumPanelHeight = maximumPanelHeight }
    if let cornerRadius { presentation.cornerRadius = cornerRadius }
    return presentation
  }

  static func centeredLoadingConfiguration() -> FKActionSheetConfiguration {
    FKActionSheetConfiguration.loading(
      .standard(
        FKActionSheetStandardLoadingContent(
          title: "Loading options",
          message: "Centered card while fetching…"
        )
      ),
      preferredPanelHeight: 180,
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation()
    )
  }

  static func presentCenteredCard(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Centered card", message: "Tap outside the card to dismiss.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Continue") { log("Centered continue") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation()
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredPlain(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Plain centered", message: "appearancePreset: .plain")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Plain centered") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .plain,
      presentation: centeredPresentation()
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredSystem(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "System centered", message: "appearancePreset: .system")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("System centered") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .system,
      presentation: centeredPresentation()
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredBackdropDismissDisabled(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Backdrop taps are ignored. Use Cancel.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Centered action") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation(allowsTapOutsideDismiss: false)
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredStrongBackdrop(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Strong backdrop", message: "backdropAlpha = 0.6")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Strong backdrop") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation(backdropAlpha: 0.6)
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredCompactCard(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Compact card", message: "maxPanelWidth 300, inset 32")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Compact centered") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation(maxPanelWidth: 300, horizontalInset: 32)
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredDestructive(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Delete draft?", message: "This cannot be undone.")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction(title: "Delete", style: .destructive) { log("Delete") },
          FKActionSheetAction(title: "Archive") { log("Archive") },
        ]),
      ],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation()
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentCenteredScrollableList(from presenter: UIViewController) {
    let rows = (1 ... 14).map { index in
      FKActionSheetAction(title: "Topic \(index)") { log("Topic \(index)") }
    }
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Notifications", message: "Scroll inside the card")),
      sections: [FKActionSheetSection(actions: rows)],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation(maximumPanelHeight: 280)
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  /// Presents a centered loading sheet; retain the returned instance for `finishLoading`.
  @discardableResult
  static func presentCenteredLoading(from presenter: UIViewController) -> FKActionSheet? {
    presentInstance(centeredLoadingConfiguration(), from: presenter, logEvents: true)
  }

  static func presentPopover(from presenter: UIViewController, anchor: UIView) {
    presentPopover(from: presenter, popoverAnchor: .sourceView(anchor))
  }

  static func presentPopover(from presenter: UIViewController, barButtonItem: UIBarButtonItem) {
    presentPopover(from: presenter, popoverAnchor: .barButtonItem(barButtonItem))
  }

  private enum PopoverAnchor {
    case sourceView(UIView)
    case barButtonItem(UIBarButtonItem)
  }

  private static func presentPopover(from presenter: UIViewController, popoverAnchor: PopoverAnchor) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Popover")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Option A") { log("Popover A") }])],
      cancelAction: makeCancelAction(),
      appearancePreset: .plain,
      presentation: .popover
    )
    do {
      let sheet = try FKActionSheet(configuration: config)
      switch popoverAnchor {
      case .sourceView(let anchor):
        try sheet.present(from: presenter, anchoredTo: anchor)
        log("present(from:anchoredTo: sourceView)")
      case .barButtonItem(let item):
        try sheet.present(from: presenter, anchoredTo: item)
        log("present(from:anchoredTo: barButtonItem)")
      }
      _ = sheet
    } catch {
      log("Popover present failed: \(error)")
    }
  }

  static func presentBackdropDismiss(from presenter: UIViewController) {
    var presentation = FKActionSheetPresentationConfiguration.default
    presentation.allowsTapOutsideDismiss = true
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Tap outside the sheet to dismiss.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Action") }])],
      cancelAction: makeCancelAction(),
      presentation: presentation
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentBackdropDismissDisabled(from presenter: UIViewController) {
    var presentation = FKActionSheetPresentationConfiguration.default
    presentation.allowsTapOutsideDismiss = false
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Backdrop taps are ignored; use Cancel.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Action") }])],
      cancelAction: makeCancelAction(),
      presentation: presentation
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentBottomSheetWithHeightCap(from presenter: UIViewController) {
    var presentation = FKActionSheetPresentationConfiguration.default
    presentation.maximumPanelHeight = 280
    presentation.maximumFitContentHeightFraction = 0.45
    let rows = (1 ... 12).map { index in
      FKActionSheetAction(title: "Row \(index)") { log("Row \(index)") }
    }
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Tall bottom sheet", message: "maximumPanelHeight = 280")),
      sections: [FKActionSheetSection(actions: rows)],
      cancelAction: makeCancelAction(),
      presentation: presentation
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  static func presentLoadingWithoutCancelWhileLoading(from presenter: UIViewController) -> FKActionSheet? {
    let loading = FKActionSheetLoadingConfiguration(
      content: .standard(
        FKActionSheetStandardLoadingContent(
          title: "Loading",
          message: "Cancel row hidden until content loads."
        )
      ),
      preferredPanelHeight: 160,
      showsCancelWhileLoading: false
    )
    let config = FKActionSheetConfiguration(
      sections: [],
      cancelAction: makeCancelAction(),
      contentMode: .loading(loading)
    )
    return presentInstance(config, from: presenter, logEvents: true)
  }

  static func presentSelectionValidationFailure(from presenter: UIViewController) {
    let a = FKActionSheetAction(title: "A")
    let b = FKActionSheetAction(title: "B")
    let c = FKActionSheetAction(title: "C")
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Three pre-selected rows but max is 2")),
      sections: [FKActionSheetSection(actions: [a, b, c])],
      cancelAction: makeCancelAction(),
      selection: FKActionSheetSelectionConfiguration(
        mode: .multiple(
          FKActionSheetSelectionConfiguration.MultipleSelection(
            scope: .allSections,
            maxSelectionCount: 2,
            disablesUnselectedRowsAtMax: true
          )
        ),
        selectedActionIDs: [a.id, b.id, c.id]
      )
    )
    do {
      try FKActionSheet.validate(config)
      log("Unexpected: over-max selection validated")
    } catch let error as FKActionSheetValidationError {
      log("validate rejected: \(error)")
      FKToast.show(error.exampleToastMessage, style: .error, kind: .toast)
    } catch {
      log("validate failed: \(error)")
    }
  }

  static func presentSingleSelectionKeepsSheetOpen(from presenter: UIViewController) {
    let email = FKActionSheetAction(title: "Email", symbolName: "envelope.fill") { log("Email") }
    let phone = FKActionSheetAction(title: "Phone", symbolName: "phone.fill") { log("Phone") }
    var selection = FKActionSheetSelectionConfiguration()
    selection.mode = .single(scope: .allSections)
    selection.keepsSheetPresentedOnSelection = true
    selection.indicatorStyle = .radio
    selection.selectedActionID = email.id
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Contact method", message: "Tap rows without dismissing; use Cancel when done.")),
      sections: [FKActionSheetSection(actions: [email, phone])],
      cancelAction: makeCancelAction(),
      dismissesAfterActionSelection: false,
      selection: selection
    )
    _ = presentInstance(config, from: presenter, logEvents: true)
  }

  static func presentCenteredSingleSelection(from presenter: UIViewController) -> FKActionSheet? {
    let email = FKActionSheetAction(title: "Email", symbolName: "envelope.fill") { log("Email") }
    let phone = FKActionSheetAction(title: "Phone", symbolName: "phone.fill") { log("Phone") }
    let chat = FKActionSheetAction(title: "Chat", symbolName: "message.fill") { log("Chat") }
    var selection = FKActionSheetSelectionConfiguration()
    selection.mode = .single(scope: .allSections)
    selection.indicatorStyle = .radio
    selection.selectedActionID = email.id
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Contact method", message: "Single selection on centered card")),
      sections: [FKActionSheetSection(actions: [email, phone, chat])],
      cancelAction: makeCancelAction(),
      appearancePreset: .card,
      presentation: centeredPresentation(),
      dismissesAfterActionSelection: false,
      selection: selection
    )
    return presentInstance(config, from: presenter, logEvents: true)
  }

  static func presentFromWindowScene(_ windowScene: UIWindowScene) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Window scene", message: "Resolved top presenter from scene.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "OK") { log("Window scene action") }])],
      cancelAction: makeCancelAction()
    )
    do {
      let sheet = try FKActionSheet(configuration: config)
      try sheet.present(in: windowScene)
      log("present(in: windowScene)")
      _ = sheet
    } catch {
      log("Window scene present failed: \(error)")
    }
  }

  // MARK: - Builder & migration

  static func presentBuilder(from presenter: UIViewController) {
    let config = FKActionSheetBuilder()
      .header(title: "Builder API", message: "Fluent configuration")
      .addSection(title: "Actions", actions: [
        FKActionSheetAction(title: "Built with builder") { log("Builder action") },
      ])
      .cancelAction(makeCancelAction())
      .handlerTiming(.afterDismissAnimation)
      .build()
    do {
      let sheet = try FKActionSheet(configuration: config)
      try sheet.present(from: presenter)
      log("Builder build() + present(from:)")
      _ = sheet
    } catch {
      log("Builder present failed: \(error)")
    }
  }

  static func presentAlertMigration(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      alertTitle: "Photo",
      message: "UIAlertAction-style construction",
      actions: [
        FKActionSheetAction(title: "Share", uiAlertActionStyle: .default) { log("Share") },
        FKActionSheetAction(title: "Delete", uiAlertActionStyle: .destructive) { log("Delete") },
      ],
      cancelTitle: "Cancel"
    )
    _ = present(config, from: presenter)
  }
}
