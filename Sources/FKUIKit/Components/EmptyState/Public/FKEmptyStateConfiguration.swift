import UIKit

// MARK: - Preset scenarios

/// High-level product scenarios used by `FKEmptyStateConfiguration.scenario(_:)` to pre-fill copy and `FKEmptyStatePhase`.
///
/// Localize strings in your app before shipping.
public enum FKEmptyStateScenario: CaseIterable, Sendable {
  /// Offline or transport failure messaging; primary action reloads.
  case noNetwork
  /// Search returned nothing.
  case noSearchResult
  /// Favorites / wishlist empty.
  case noFavorites
  /// Order history empty.
  case noOrders
  /// Inbox / notifications empty.
  case noMessages
  /// Request failed; uses `phase == .error` and mandatory retry styling.
  case loadFailed
  /// Authorization / feature gate.
  case noPermission
  /// Account required.
  case notLoggedIn
}

// MARK: - Model

/// Aggregate configuration for `FKEmptyStateView`; compose sub-configurations or use scenario/resolver factories.
public struct FKEmptyStateConfiguration {
  /// Controls which layout branch runs inside `FKEmptyStateView` (loading vs empty/error vs hidden).
  public var phase: FKEmptyStatePhase

  /// High-level semantic type used by i18n presets and state resolution helpers.
  ///
  /// This is intentionally separate from `phase`:
  /// - `phase` controls the rendering pipeline (loading vs non-loading vs hidden).
  /// - `type` communicates intent (offline, noResults, permissionDenied, etc.).
  public var type: FKEmptyStateType

  /// Copy, illustration, and loading subtitle.
  public var content: FKEmptyStateContentConfiguration

  /// Layout hints and optional overrides.
  public var layout: FKEmptyStateLayoutConfiguration

  /// Typography, buttons, background, and loading chrome.
  public var appearance: FKEmptyStateAppearanceConfiguration

  /// Action buttons rendered below the text stack.
  ///
  /// - Important: UIKit rendering maps `primary` → filled button, `secondary` → bordered button,
  ///   `tertiary` → plain button. Override chrome via ``appearance/buttons/secondary`` / ``appearance/buttons/tertiary``.
  ///   Action events are emitted by id.
  public var actions: FKEmptyStateActionSet

  /// Overlay behavior, animation, and accessibility announcements.
  public var presentation: FKEmptyStatePresentationConfiguration

  /// Optional advanced composition slots.
  public var slots: FKEmptyStateSlotConfiguration

  public init(
    phase: FKEmptyStatePhase = .empty,
    type: FKEmptyStateType = .empty,
    content: FKEmptyStateContentConfiguration = FKEmptyStateContentConfiguration(),
    layout: FKEmptyStateLayoutConfiguration = FKEmptyStateLayoutConfiguration(),
    appearance: FKEmptyStateAppearanceConfiguration = FKEmptyStateAppearanceConfiguration(),
    actions: FKEmptyStateActionSet = FKEmptyStateActionSet(),
    presentation: FKEmptyStatePresentationConfiguration = FKEmptyStatePresentationConfiguration(),
    slots: FKEmptyStateSlotConfiguration = FKEmptyStateSlotConfiguration()
  ) {
    self.phase = phase
    self.type = type
    self.content = content
    self.layout = layout
    self.appearance = appearance
    self.actions = actions
    self.presentation = presentation
    self.slots = slots
  }
}

// MARK: - Convenience initializer

public extension FKEmptyStateConfiguration {
  /// Builds a configuration from common content fields without touching layout or presentation defaults.
  init(
    phase: FKEmptyStatePhase = .empty,
    type: FKEmptyStateType = .empty,
    image: UIImage? = nil,
    title: String? = nil,
    description: String? = nil,
    primaryActionTitle: String? = nil,
    primaryActionID: String = "primary"
  ) {
    var content = FKEmptyStateContentConfiguration(title: title, description: description)
    content.setImage(image)

    let actions: FKEmptyStateActionSet
    if let primaryActionTitle, !primaryActionTitle.isEmpty {
      actions = .primary(primaryActionTitle, id: primaryActionID)
    } else {
      actions = FKEmptyStateActionSet()
    }

    self.init(
      phase: phase,
      type: type,
      content: content,
      actions: actions
    )
  }
}

// MARK: - Factory & fluent helpers

public extension FKEmptyStateConfiguration {
  /// Default retry title when `phase == .error` and no primary action is configured.
  static var defaultRetryButtonTitle: String { FKUIKitI18n.string("fkuikit.empty.action.retry") }

  /// Returns a configuration pre-filled for `scenario`.
  static func scenario(_ scenario: FKEmptyStateScenario) -> FKEmptyStateConfiguration {
    switch scenario {
    case .noNetwork:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .offline,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("wifi.exclamationmark"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.no_network.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.no_network.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .section),
        actions: .primary(
          FKUIKitI18n.string("fkuikit.empty.scenario.no_network.action"),
          id: "retry"
        )
      )
    case .noSearchResult:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .noResults,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("magnifyingglass"),
          title: FKUIKitI18n.string("fkuikit.empty.noResults.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.no_search.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .search)
      )
    case .noFavorites:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("heart.slash"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .list),
        actions: .primary(FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.action"))
      )
    case .noOrders:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("shippingbox"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .list),
        actions: .primary(FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.action"))
      )
    case .noMessages:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("tray.full"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.no_messages.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.no_messages.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .list)
      )
    case .loadFailed:
      return FKEmptyStateConfiguration(
        phase: .error,
        type: .error,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("exclamationmark.arrow.trianglehead.clockwise"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .section),
        actions: .primary(defaultRetryButtonTitle, id: "retry")
      )
    case .noPermission:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .permissionDenied,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("lock.shield"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.no_permission.title"),
          description: FKUIKitI18n.string("fkuikit.empty.permissionDenied.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .section),
        actions: .primary(FKUIKitI18n.string("fkuikit.common.ok"))
      )
    case .notLoggedIn:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .newUser,
        content: FKEmptyStateContentConfiguration(
          image: scenarioImage("person.crop.circle.badge.exclamationmark"),
          title: FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.title"),
          description: FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.description")
        ),
        layout: FKEmptyStateLayoutConfiguration(context: .fullPage),
        actions: .primary(FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.action"))
      )
    }
  }

  /// Builds a configuration from ``FKEmptyStateResolver`` output and optional input metadata.
  ///
  /// Returns `phase == .content` when the resolver yields `.none`. Error descriptions from
  /// ``FKEmptyStateInputs/errorDescription`` override the preset body copy for `.error`.
  static func resolved(from input: FKEmptyStateInputs) -> FKEmptyStateConfiguration {
    switch FKEmptyStateResolver.resolve(input) {
    case .none:
      return FKEmptyStateConfiguration(phase: .content)
    case let .show(type):
      return configuration(for: type, input: input)
    }
  }

  private static func scenarioImage(_ systemName: String) -> FKEmptyStateImageContent {
    .systemSymbol(systemName)
  }

  private static func configuration(for type: FKEmptyStateType, input: FKEmptyStateInputs) -> FKEmptyStateConfiguration {
    switch type {
    case .offline:
      return scenario(.noNetwork)
    case .noResults:
      return scenario(.noSearchResult)
    case .error:
      var config = scenario(.loadFailed)
      if let errorDescription = input.errorDescription, !errorDescription.isEmpty {
        config.content.description = errorDescription
      }
      return config
    case .permissionDenied:
      return scenario(.noPermission)
    case .newUser:
      return scenario(.notLoggedIn)
    case .empty:
      return scenario(.noMessages)
    case .loading:
      return FKEmptyStateConfiguration(phase: .loading, type: .loading)
    case .notFound:
      var config = scenario(.noMessages)
      config.type = .notFound
      return config
    case .maintenance:
      var config = customState(
        identifier: "maintenance",
        title: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.description"),
        buttonTitle: defaultRetryButtonTitle,
        buttonID: "retry"
      )
      config.type = .maintenance
      config.content.image = scenarioImage("wrench.and.screwdriver")
      return config
    }
  }

  /// Returns a configuration for a custom business state identifier.
  ///
  /// - Parameters:
  ///   - identifier: Domain-specific key, such as `"maintenance"` or `"geo_restricted"`.
  ///   - title: Primary title.
  ///   - description: Secondary message.
  ///   - buttonTitle: Optional action title.
  static func customState(
    identifier: String,
    title: String?,
    description: String? = nil,
    buttonTitle: String? = nil,
    buttonID: String = "primary"
  ) -> FKEmptyStateConfiguration {
    let actions: FKEmptyStateActionSet
    if let buttonTitle, !buttonTitle.isEmpty {
      actions = .primary(buttonTitle, id: buttonID)
    } else {
      actions = FKEmptyStateActionSet()
    }
    return FKEmptyStateConfiguration(
      phase: .custom(identifier),
      content: FKEmptyStateContentConfiguration(title: title, description: description),
      actions: actions
    )
  }

  /// Returns a copy with `content.title` replaced.
  func withTitle(_ text: String?) -> Self {
    var copy = self
    copy.content.title = text
    return copy
  }

  /// Returns a copy with `content.description` replaced.
  func withDescription(_ text: String?) -> Self {
    var copy = self
    copy.content.description = text
    return copy
  }

  /// Returns a copy with the built-in illustration replaced.
  func withImage(_ image: UIImage?) -> Self {
    var copy = self
    copy.content.setImage(image)
    return copy
  }

  /// Returns a copy with `content.image.tintColor` replaced when an illustration is already configured.
  func withImageTintColor(_ color: UIColor?) -> Self {
    var copy = self
    guard copy.content.image != nil else { return copy }
    copy.content.image?.tintColor = color
    return copy
  }

  /// Returns a copy with `layout.density` replaced.
  func withDensity(_ density: FKEmptyStateDensity) -> Self {
    var copy = self
    copy.layout.density = density
    return copy
  }

  /// Returns a copy with `layout.axis` replaced.
  func withAxis(_ axis: FKEmptyStateAxis) -> Self {
    var copy = self
    copy.layout.axis = axis
    return copy
  }

  /// Returns a copy with `presentation.transition` replaced.
  func withTransition(_ transition: FKEmptyStateTransition) -> Self {
    var copy = self
    copy.presentation.transition = transition
    return copy
  }

  /// Returns a copy with `layout.context` replaced.
  func withContext(_ context: FKEmptyStateLayoutContext) -> Self {
    var copy = self
    copy.layout.context = context
    return copy
  }

  /// Returns a copy with the primary action replaced; pass `nil` to remove it.
  func withPrimaryAction(
    _ title: String?,
    id: String = "primary",
    kind: FKEmptyStateActionKind = .primary
  ) -> Self {
    var copy = self
    if let title, !title.isEmpty {
      copy.actions.primary = FKEmptyStateAction(id: id, title: title, kind: kind)
    } else {
      copy.actions.primary = nil
    }
    return copy
  }

  /// Returns a copy after mutating ``actions``.
  func updatingActions(_ body: (inout FKEmptyStateActionSet) -> Void) -> Self {
    var copy = self
    body(&copy.actions)
    return copy
  }

  /// Returns a copy with `phase` replaced.
  func withPhase(_ phase: FKEmptyStatePhase) -> Self {
    var copy = self
    copy.phase = phase
    return copy
  }

  /// Returns a copy with top/center alignment and vertical offset.
  func withLayout(alignment: FKEmptyStateContentAlignment, verticalOffset: CGFloat = 0) -> Self {
    var copy = self
    copy.layout.contentAlignment = alignment
    copy.layout.verticalOffset = verticalOffset
    return copy
  }

  /// Returns a copy after mutating ``content``.
  func updatingContent(_ body: (inout FKEmptyStateContentConfiguration) -> Void) -> Self {
    var copy = self
    body(&copy.content)
    return copy
  }

  /// Returns a copy after mutating ``layout``.
  func updatingLayout(_ body: (inout FKEmptyStateLayoutConfiguration) -> Void) -> Self {
    var copy = self
    body(&copy.layout)
    return copy
  }

  /// Returns a copy after mutating ``appearance``.
  func updatingAppearance(_ body: (inout FKEmptyStateAppearanceConfiguration) -> Void) -> Self {
    var copy = self
    body(&copy.appearance)
    return copy
  }

  /// Returns a copy after mutating ``presentation``.
  func updatingPresentation(_ body: (inout FKEmptyStatePresentationConfiguration) -> Void) -> Self {
    var copy = self
    body(&copy.presentation)
    return copy
  }
}

// MARK: - Global defaults (FKBadge-style)

/// Namespace for app-wide EmptyState defaults and batch helpers.
///
/// Mirrors ``FKBadge`` + ``FKBadge/defaultConfiguration``; use the `default*` baselines
/// for `UIView.fk_setEmptyState(…)` and copy-then-mutate flows at the screen level.
@MainActor
public enum FKEmptyState {
  /// Baseline typography, colors, and button style.
  public static var defaultAppearance = FKEmptyStateAppearanceConfiguration(
    typography: FKEmptyStateTypography(),
    buttons: FKEmptyStateButtonAppearance(
      primary: FKEmptyStateButtonStyle(
        titleColor: .white,
        font: .systemFont(ofSize: 15, weight: .semibold),
        backgroundColor: .systemBlue,
        cornerRadius: 10
      )
    ),
    background: FKEmptyStateBackgroundAppearance(color: .systemBackground)
  )

  /// Baseline layout hints shared across screens.
  public static var defaultLayout = FKEmptyStateLayoutConfiguration()

  /// Baseline overlay behavior shared across screens.
  public static var defaultPresentation = FKEmptyStatePresentationConfiguration()

  /// Baseline actions shared across screens (usually empty).
  public static var defaultActions = FKEmptyStateActionSet()

  /// Baseline aggregate built from ``defaultAppearance``, ``defaultLayout``, ``defaultActions``, and ``defaultPresentation``.
  public static var defaultConfiguration: FKEmptyStateConfiguration {
    FKEmptyStateConfiguration(
      layout: defaultLayout,
      appearance: defaultAppearance,
      actions: defaultActions,
      presentation: defaultPresentation
    )
  }

  /// Mutates a copy of ``defaultConfiguration`` and writes global defaults back (typical app-launch branding setup).
  public static func configureDefault(_ body: (inout FKEmptyStateConfiguration) -> Void) {
    fk_emptyStateAssertMainThread()
    var copy = defaultConfiguration
    body(&copy)
    defaultAppearance = copy.appearance
    defaultLayout = copy.layout
    defaultActions = copy.actions
    defaultPresentation = copy.presentation
  }

  /// Mutates ``defaultAppearance`` in place.
  public static func configureAppearance(_ body: (inout FKEmptyStateAppearanceConfiguration) -> Void) {
    fk_emptyStateAssertMainThread()
    body(&defaultAppearance)
  }

  /// Mutates ``defaultLayout`` in place.
  public static func configureLayout(_ body: (inout FKEmptyStateLayoutConfiguration) -> Void) {
    fk_emptyStateAssertMainThread()
    body(&defaultLayout)
  }

  /// Mutates ``defaultPresentation`` in place.
  public static func configurePresentation(_ body: (inout FKEmptyStatePresentationConfiguration) -> Void) {
    fk_emptyStateAssertMainThread()
    body(&defaultPresentation)
  }
}
