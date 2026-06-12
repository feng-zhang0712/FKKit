import Foundation

/// Configuration for ``FKFormSectionHeaderView`` (X-10).
public struct FKFormSectionHeaderConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?

  /// Creates a form section header configuration.
  public init(title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }
}
