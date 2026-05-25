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
  ) -> FKActionSheetHandle? {
    let config = logEvents ? withEventLogging(configuration) : configuration
    do {
      let handle = try FKActionSheet.present(configuration: config, from: presenter)
      log("Presented sheet")
      return handle
    } catch {
      log("Present failed: \(error)")
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
    _ = present(config, from: presenter)
  }

  static func presentConvenienceAPI(from presenter: UIViewController) {
    do {
      _ = try FKActionSheet.present(
        title: "Quick Sheet",
        message: "Uses the title/message convenience API.",
        actions: [
          FKActionSheetAction(title: "OK") { log("OK") },
        ],
        cancelAction: makeCancelAction(),
        hostContext: FKActionSheetPresentationHostContext(presenter: presenter)
      )
      log("Convenience present succeeded")
    } catch {
      log("Convenience present failed: \(error)")
    }
  }

  static func presentValidationFailure(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(sections: [])
    do {
      try FKActionSheet.validate(config, hostContext: FKActionSheetPresentationHostContext(presenter: presenter))
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

  static func presentDisabledAndLoading(from presenter: UIViewController) -> FKActionSheetHandle? {
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

  // MARK: - Selection

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
      handler: { log("Custom row selected") },
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

  // MARK: - Live updates

  static func presentForLiveReload(from presenter: UIViewController) -> FKActionSheetHandle? {
    var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
    share.isLoading = false
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Use page buttons to reload or update rows.")),
      sections: [FKActionSheetSection(actions: [share])],
      cancelAction: makeCancelAction()
    )
    return present(config, from: presenter)
  }

  static func presentOnceDemo(from presenter: UIViewController) {
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Second presentOnce with same id is ignored.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Done") { log("Done") }])],
      cancelAction: makeCancelAction()
    )
    do {
      if let handle = try FKActionSheet.presentOnce(id: "fk.examples.actionsheet", configuration: config, from: presenter) {
        log("presentOnce returned handle")
        _ = handle
      } else {
        log("presentOnce skipped (already presenting for id)")
      }
    } catch {
      log("presentOnce failed: \(error)")
    }
  }

  static func presentSwipeAndBackdropOptions(from presenter: UIViewController) {
    var presentation = FKActionSheetPresentationConfiguration.default
    presentation.allowsSwipeDismiss = true
    presentation.allowsTapOutsideDismiss = true
    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(message: "Swipe down or tap outside to dismiss.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Action") { log("Action") }])],
      cancelAction: makeCancelAction(),
      presentation: presentation
    )
    _ = present(config, from: presenter, logEvents: true)
  }

  // MARK: - Builder & migration

  static func presentBuilder(from presenter: UIViewController) {
    do {
      _ = try FKActionSheetBuilder()
        .header(title: "Builder API", message: "Fluent configuration")
        .addSection(title: "Actions", actions: [
          FKActionSheetAction(title: "Built with builder") { log("Builder action") },
        ])
        .cancelAction(makeCancelAction())
        .handlerTiming(.afterDismissAnimation)
        .present(from: presenter)
      log("Builder present succeeded")
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
