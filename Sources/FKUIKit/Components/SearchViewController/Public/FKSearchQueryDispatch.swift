import Foundation

/// Whether ``FKSearchViewController`` runs built-in provider/list updates for a query.
public enum FKSearchQueryDispatch: Sendable, Equatable {
  /// Run local filter or remote provider and update the results surface.
  case performBuiltIn
  /// Skip built-in results; host handles navigation or custom UI via callbacks/delegate.
  case handledByHost
}
