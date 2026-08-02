import Foundation

/// Shared main-actor marshaling for Skeleton UI mutations.
enum FKSkeletonDispatch {
  static func runOnMain(_ work: @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
      MainActor.assumeIsolated(work)
    } else {
      Task { @MainActor in
        work()
      }
    }
  }
}
