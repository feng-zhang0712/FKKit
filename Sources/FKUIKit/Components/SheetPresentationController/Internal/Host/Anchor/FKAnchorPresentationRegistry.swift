import UIKit

/// Tracks active anchor presentations per host/source scope so repeat `present` calls do not stack overlays.
@MainActor
enum FKAnchorPresentationRegistry {
  struct Key: Hashable {
    let hostViewID: ObjectIdentifier
    let anchorSourceID: ObjectIdentifier?
  }

  private static var entries: [Key: FKWeakReference<FKSheetPresentationController>] = [:]

  static func existingController(for key: Key) -> FKSheetPresentationController? {
    prune()
    return entries[key]?.object
  }

  static func register(_ controller: FKSheetPresentationController, for key: Key) {
    prune()
    entries[key] = FKWeakReference(controller)
  }

  static func unregister(_ controller: FKSheetPresentationController) {
    entries = entries.filter { $0.value.object !== controller }
  }

  private static func prune() {
    entries = entries.filter { $0.value.object != nil }
  }
}
