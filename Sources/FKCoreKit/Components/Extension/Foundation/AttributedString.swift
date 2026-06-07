import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension AttributedString {
  /// Plain-text content without attribute metadata.
  var fk_plainString: String {
    String(characters)
  }
}
