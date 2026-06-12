import Foundation

/// Tappable footer or inline action link for rich card rows (D-07, D-09, D-12).
public struct FKCellActionLink: Sendable, Equatable {
  public var title: String
  public var url: URL?
  public var identifier: String?

  /// Creates an action link payload.
  public init(title: String, url: URL? = nil, identifier: String? = nil) {
    self.title = title
    self.url = url
    self.identifier = identifier
  }
}
