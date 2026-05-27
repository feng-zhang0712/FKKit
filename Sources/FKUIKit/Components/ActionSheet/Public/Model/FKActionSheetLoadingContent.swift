import UIKit

/// Built-in loading stack (activity indicator, title, message).
///
/// Each element is optional. Combine any subset — for example spinner-only, title-only,
/// or title + message without a spinner. At least one visible element is required.
public struct FKActionSheetStandardLoadingContent: Equatable {
  /// When `true`, shows an activity indicator above the title.
  public var showsActivityIndicator: Bool
  /// Style passed to `UIActivityIndicatorView`.
  public var activityIndicatorStyle: UIActivityIndicatorView.Style
  /// Optional tint for the activity indicator; `nil` uses the system default.
  public var activityIndicatorColor: UIColor?
  /// Optional primary line below the indicator.
  public var title: String?
  /// Optional secondary line below the title.
  public var message: String?
  /// Title font; `nil` uses ``FKActionSheetAppearance/headerTitleFont`` at a larger body scale.
  public var titleFont: UIFont?
  /// Message font; `nil` uses ``FKActionSheetAppearance/headerMessageFont``.
  public var messageFont: UIFont?
  /// Title color; `nil` uses ``FKActionSheetAppearance/headerTitleColor``.
  public var titleColor: UIColor?
  /// Message color; `nil` uses ``FKActionSheetAppearance/headerMessageColor``.
  public var messageColor: UIColor?
  /// Vertical spacing between indicator, title, and message.
  public var stackSpacing: CGFloat
  /// VoiceOver label for the loading stack; defaults to title and message when omitted.
  public var accessibilityLabel: String?

  /// Creates standard loading content.
  public init(
    showsActivityIndicator: Bool = true,
    activityIndicatorStyle: UIActivityIndicatorView.Style = .large,
    activityIndicatorColor: UIColor? = nil,
    title: String? = nil,
    message: String? = nil,
    titleFont: UIFont? = nil,
    messageFont: UIFont? = nil,
    titleColor: UIColor? = nil,
    messageColor: UIColor? = nil,
    stackSpacing: CGFloat = 12,
    accessibilityLabel: String? = nil
  ) {
    self.showsActivityIndicator = showsActivityIndicator
    self.activityIndicatorStyle = activityIndicatorStyle
    self.activityIndicatorColor = activityIndicatorColor
    self.title = title
    self.message = message
    self.titleFont = titleFont
    self.messageFont = messageFont
    self.titleColor = titleColor
    self.messageColor = messageColor
    self.stackSpacing = max(0, stackSpacing)
    self.accessibilityLabel = accessibilityLabel
  }
}

public extension FKActionSheetStandardLoadingContent {
  /// Whether at least one loading element (spinner, title, or message) is configured.
  var hasVisibleContent: Bool {
    showsActivityIndicator
      || !(title?.isEmpty ?? true)
      || !(message?.isEmpty ?? true)
  }
}

/// Builds and optionally updates custom loading content.
public final class FKActionSheetCustomLoadingProvider: @unchecked Sendable {
  /// Creates a new loading view.
  public var build: @MainActor (FKActionSheetLoadingBuildContext) -> UIView
  /// Optional in-place update when the same view instance is reused.
  public var update: (@MainActor (FKActionSheetLoadingBuildContext, UIView) -> Void)?

  /// Creates a custom loading provider.
  public init(
    build: @escaping @MainActor (FKActionSheetLoadingBuildContext) -> UIView,
    update: (@MainActor (FKActionSheetLoadingBuildContext, UIView) -> Void)? = nil
  ) {
    self.build = build
    self.update = update
  }
}

/// Host-provided loading view configuration.
public struct FKActionSheetCustomLoadingContent: Equatable {
  /// Stable identifier.
  public let id: UUID
  /// VoiceOver label for the loading container.
  public var accessibilityLabel: String?
  /// When `true`, pins the built view to the loading body margins instead of centering by intrinsic size.
  public var fillsAvailableArea: Bool
  /// View builder.
  public var provider: FKActionSheetCustomLoadingProvider

  /// Creates custom loading content.
  public init(
    id: UUID = UUID(),
    accessibilityLabel: String? = nil,
    fillsAvailableArea: Bool = false,
    provider: FKActionSheetCustomLoadingProvider
  ) {
    self.id = id
    self.accessibilityLabel = accessibilityLabel
    self.fillsAvailableArea = fillsAvailableArea
    self.provider = provider
  }

  public static func == (lhs: FKActionSheetCustomLoadingContent, rhs: FKActionSheetCustomLoadingContent) -> Bool {
    lhs.id == rhs.id
      && lhs.accessibilityLabel == rhs.accessibilityLabel
      && lhs.fillsAvailableArea == rhs.fillsAvailableArea
  }
}

/// Loading body content.
public enum FKActionSheetLoadingContent: Equatable {
  /// Built-in activity indicator with optional title and message.
  case standard(FKActionSheetStandardLoadingContent)
  /// Host-provided loading view.
  case custom(FKActionSheetCustomLoadingContent)
}

/// Layout and presentation settings for the loading state.
public struct FKActionSheetLoadingConfiguration: Equatable {
  /// Loading body (built-in spinner stack or custom view).
  public var content: FKActionSheetLoadingContent
  /// Preferred height of the loading body area (excluding cancel row and safe-area padding).
  public var preferredPanelHeight: CGFloat
  /// Insets around the loading body inside the panel.
  public var contentInsets: NSDirectionalEdgeInsets
  /// When `true` and `cancelAction` is set, the cancel row remains visible below the loading body.
  public var showsCancelWhileLoading: Bool

  /// Creates loading configuration with the built-in spinner stack.
  public init(
    preferredPanelHeight: CGFloat = 180,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24),
    showsCancelWhileLoading: Bool = true,
    standardContent: FKActionSheetStandardLoadingContent = FKActionSheetStandardLoadingContent()
  ) {
    self.init(
      content: .standard(standardContent),
      preferredPanelHeight: preferredPanelHeight,
      contentInsets: contentInsets,
      showsCancelWhileLoading: showsCancelWhileLoading
    )
  }

  /// Creates loading configuration.
  public init(
    content: FKActionSheetLoadingContent,
    preferredPanelHeight: CGFloat = 180,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24),
    showsCancelWhileLoading: Bool = true
  ) {
    self.content = content
    self.preferredPanelHeight = max(44, preferredPanelHeight)
    self.contentInsets = contentInsets
    self.showsCancelWhileLoading = showsCancelWhileLoading
  }
}

/// Describes whether the sheet shows action rows or a loading presentation.
public enum FKActionSheetContentMode: Equatable {
  /// Renders configured sections and optional cancel row.
  case actions
  /// Renders a centered loading presentation; sections may be empty until data arrives.
  case loading(FKActionSheetLoadingConfiguration)
}

/// Context passed to custom loading builders.
@MainActor
public struct FKActionSheetLoadingBuildContext {
  /// Active appearance.
  public let appearance: FKActionSheetAppearance
  /// Available width for layout.
  public let boundsWidth: CGFloat
  /// Available height for the loading body area.
  public let boundsHeight: CGFloat

  /// Creates a loading build context.
  public init(appearance: FKActionSheetAppearance, boundsWidth: CGFloat, boundsHeight: CGFloat) {
    self.appearance = appearance
    self.boundsWidth = max(1, boundsWidth)
    self.boundsHeight = max(1, boundsHeight)
  }
}

public extension FKActionSheetConfiguration {
  /// Whether the configuration currently presents the loading body.
  var isLoadingContentActive: Bool {
    if case .loading = contentMode { return true }
    return false
  }

  /// Active loading configuration when ``contentMode`` is ``FKActionSheetContentMode/loading(_:)``.
  var loadingConfiguration: FKActionSheetLoadingConfiguration? {
    if case .loading(let configuration) = contentMode {
      return configuration
    }
    return nil
  }
}
