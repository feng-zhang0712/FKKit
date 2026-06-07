import Foundation

public extension BinaryInteger {
  /// `true` when the value is even.
  var fk_isEven: Bool {
    isMultiple(of: 2)
  }

  /// `true` when the value is odd.
  var fk_isOdd: Bool {
    !fk_isEven
  }

  /// Human-readable byte size (1024-based), e.g. `"1.2 MB"`.
  var fk_byteCountDescription: String {
    ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
  }
}
