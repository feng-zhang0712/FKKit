import FKCoreKit
import UIKit

/// Resolved action row used by alert layout and callbacks.
struct FKAlertResolvedAction: Sendable {
  enum Role: Sendable, Equatable {
    case primary
    case destructive
    case cancel
  }

  /// Original index in the caller-provided `actions` array.
  let sourceIndex: Int
  /// Action descriptor.
  let action: FKAlertAction
  /// Layout role determining button styling and ordering.
  let role: Role
}

enum FKAlertActionResolver {
  private static let maximumVisibleActions = 3

  static func normalizedActions(for content: FKAlertContent) -> [FKAlertAction] {
    if content.actions.isEmpty {
      return [
        FKAlertAction(
          title: FKI18n.string("fkcore.common.ok"),
          style: .default,
          handler: nil
        ),
      ]
    }
    return trimmedActions(content.actions)
  }

  static func resolvedActions(from actions: [FKAlertAction]) -> [FKAlertResolvedAction] {
    let indexed = actions.enumerated().map { ($0.offset, $0.element) }
    let cancel = indexed.last(where: { $0.1.style == .cancel })
    let destructive = indexed.first(where: { $0.1.style == .destructive })
    let defaults = indexed.filter { $0.1.style == .default }

    var resolved: [FKAlertResolvedAction] = []
    for (index, action) in defaults {
      resolved.append(.init(sourceIndex: index, action: action, role: .primary))
    }
    if let destructive {
      resolved.append(.init(sourceIndex: destructive.0, action: destructive.1, role: .destructive))
    }
    if let cancel {
      resolved.append(.init(sourceIndex: cancel.0, action: cancel.1, role: .cancel))
    }
    return resolved
  }

  static func validateContent(_ content: FKAlertContent) {
    let hasTitle = !(content.title?.isEmpty ?? true)
    let hasMessage = !(content.message?.isEmpty ?? true) || hasNonEmptyAttributedMessage(content.attributedMessage)
    let hasIcon: Bool = {
      guard let icon = content.icon else { return false }
      if case .none = icon { return false }
      return true
    }()
    let hasTextInput = content.textInput != nil
    assert(
      hasTitle || hasMessage || hasIcon || hasTextInput,
      "FKAlertContent requires at least one of title, message, icon, or textInput."
    )
  }

  private static func hasNonEmptyAttributedMessage(_ data: Data?) -> Bool {
    guard let data,
          let attributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) else {
      return false
    }
    return !attributed.string.isEmpty
  }

  private static func trimmedActions(_ actions: [FKAlertAction]) -> [FKAlertAction] {
    guard actions.count > maximumVisibleActions else { return actions }
    assertionFailure("FKAlert supports at most \(maximumVisibleActions) visible actions; trimming extras.")

    let cancel = actions.last(where: { $0.style == .cancel })
    let destructive = actions.first(where: { $0.style == .destructive })
    let firstDefault = actions.first(where: { $0.style == .default })

    var trimmed: [FKAlertAction] = []
    if let firstDefault { trimmed.append(firstDefault) }
    if let destructive { trimmed.append(destructive) }
    if let cancel { trimmed.append(cancel) }
    return trimmed.isEmpty ? Array(actions.prefix(maximumVisibleActions)) : trimmed
  }
}

extension FKAlertPresentationConfiguration {
  @MainActor
  static func makeDefaultSheet() -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.centerAlert
    if case .center(var center) = configuration.layout {
      center.size = .fitted(maxSize: CGSize(width: 320, height: 680))
      configuration.layout = .center(center)
    }
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.preferredContentSizePolicy = .strict
    configuration.sheet.scrollTrackingStrategy = .automatic
    configuration.dismissBehavior.allowsBackdropTap = false
    return configuration
  }

  @MainActor
  func resolvedSheetConfiguration(
    for content: FKAlertContent,
    motion: FKAlertMotionConfiguration
  ) -> FKSheetPresentationConfiguration {
    var resolved = sheet ?? Self.makeDefaultSheet()
    resolved.dismissBehavior.allowsTapOutside = allowsBackdropTapToDismiss
    resolved.dismissBehavior.allowsBackdropTap = allowsBackdropTapToDismiss
    resolved.dismissBehavior.allowsSwipe = allowsSwipeToDismiss

    if case .center(var center) = resolved.layout {
      center.dismissEnabled = allowsSwipeToDismiss
      resolved.layout = .center(center)
    }

    if content.dangerousAction != nil {
      resolved.dismissBehavior.allowsTapOutside = false
      resolved.dismissBehavior.allowsBackdropTap = false
      resolved.dismissBehavior.allowsSwipe = false
      if case .center(var center) = resolved.layout {
        center.dismissEnabled = false
        resolved.layout = .center(center)
      }
    }

    if let cornerRadius {
      resolved.cornerRadius = cornerRadius
    }

    if motion.respectsReduceMotion, UIAccessibility.isReduceMotionEnabled {
      resolved.animation.preset = .fade
    }

    return resolved
  }
}
