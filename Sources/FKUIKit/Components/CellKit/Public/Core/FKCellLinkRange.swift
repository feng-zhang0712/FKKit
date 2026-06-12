import Foundation

/// Identifies a tappable link range inside section footer copy.
public struct FKCellLinkRange: Sendable, Equatable, Hashable {
  public var location: Int
  public var length: Int
  public var url: URL?
  public var identifier: String?

  /// Creates a link range using UTF-16 indices compatible with `NSString` APIs.
  public init(location: Int, length: Int, url: URL? = nil, identifier: String? = nil) {
    self.location = location
    self.length = length
    self.url = url
    self.identifier = identifier
  }

  /// Converts to `NSRange` for attributed string styling.
  public var nsRange: NSRange {
    NSRange(location: location, length: length)
  }
}
