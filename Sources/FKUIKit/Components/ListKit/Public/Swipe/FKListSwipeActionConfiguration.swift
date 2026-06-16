import UIKit

// MARK: - Style

/// Visual style for table swipe actions.
public enum FKListSwipeActionStyle: Sendable, Equatable {
  case normal
  case destructive
  case cancel
}

// MARK: - Icon

/// Optional SF Symbol metadata for swipe actions.
public struct FKListSwipeActionIcon: Sendable, Equatable, Hashable {
  public var symbolName: String

  public init(symbolName: String) {
    self.symbolName = symbolName
  }
}

// MARK: - Action

/// Swipe action descriptor; handlers are registered in ``FKListSwipeActionHandlerRegistry``.
public struct FKListSwipeAction: Sendable, Equatable, Hashable, Identifiable {
  public var id: String
  public var title: String
  public var style: FKListSwipeActionStyle
  public var icon: FKListSwipeActionIcon?

  public init(
    id: String,
    title: String,
    style: FKListSwipeActionStyle = .normal,
    icon: FKListSwipeActionIcon? = nil
  ) {
    self.id = id
    self.title = title
    self.style = style
    self.icon = icon
  }
}

// MARK: - Configuration

/// Per-item swipe action layout.
public struct FKListSwipeActionConfiguration: Sendable, Equatable, Hashable {
  public var leading: [FKListSwipeAction]
  public var trailing: [FKListSwipeAction]
  public var permitsFullSwipe: Bool

  public init(
    leading: [FKListSwipeAction] = [],
    trailing: [FKListSwipeAction] = [],
    permitsFullSwipe: Bool = false
  ) {
    self.leading = leading
    self.trailing = trailing
    self.permitsFullSwipe = permitsFullSwipe
  }
}

// MARK: - Handler registry

/// Stores swipe action handlers outside equatable configuration structs.
@MainActor
public final class FKListSwipeActionHandlerRegistry {
  public init() {}

  private var handlers: [String: @MainActor @Sendable (FKListItemID) -> Void] = [:]

  /// Registers a handler keyed by action id.
  public func register(
    id: String,
    handler: @escaping @MainActor @Sendable (FKListItemID) -> Void
  ) {
    handlers[id] = handler
  }

  /// Removes a registered handler.
  public func removeHandler(id: String) {
    handlers.removeValue(forKey: id)
  }

  /// Returns the handler for `id` when registered.
  public func handler(for id: String) -> (@MainActor @Sendable (FKListItemID) -> Void)? {
    handlers[id]
  }
}

// MARK: - Switch / checkbox registries

/// Stores switch toggle handlers keyed by ``FKListSwitchRow/handlerID``.
@MainActor
public final class FKListSwitchHandlerRegistry {
  public init() {}

  private var handlers: [String: @MainActor @Sendable (FKListItemID, Bool) -> Void] = [:]

  public func register(
    id: String,
    handler: @escaping @MainActor @Sendable (FKListItemID, Bool) -> Void
  ) {
    handlers[id] = handler
  }

  public func handler(for id: String) -> (@MainActor @Sendable (FKListItemID, Bool) -> Void)? {
    handlers[id]
  }
}

/// Stores checkbox toggle handlers keyed by ``FKListCheckboxRow/handlerID``.
@MainActor
public final class FKListCheckboxHandlerRegistry {
  public init() {}

  private var handlers: [String: @MainActor @Sendable (FKListItemID, Bool) -> Void] = [:]

  public func register(
    id: String,
    handler: @escaping @MainActor @Sendable (FKListItemID, Bool) -> Void
  ) {
    handlers[id] = handler
  }

  public func handler(for id: String) -> (@MainActor @Sendable (FKListItemID, Bool) -> Void)? {
    handlers[id]
  }
}
