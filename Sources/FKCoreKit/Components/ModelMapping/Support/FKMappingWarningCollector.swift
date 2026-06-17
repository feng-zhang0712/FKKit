import Foundation

final class FKMappingWarningCollector: @unchecked Sendable {
  private let lock = NSLock()
  private var items: [FKMappingWarning] = []

  func append(_ warning: FKMappingWarning) {
    lock.lock()
    defer { lock.unlock() }
    items.append(warning)
  }

  var all: [FKMappingWarning] {
    lock.lock()
    defer { lock.unlock() }
    return items
  }
}
