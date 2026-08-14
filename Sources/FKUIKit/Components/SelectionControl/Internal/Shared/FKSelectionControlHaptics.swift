import UIKit

@MainActor
enum FKSelectionControlHaptics {
  static func fire(_ style: FKSelectionControlHaptic) {
    switch style {
    case .none:
      break
    case .light:
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .selection:
      UISelectionFeedbackGenerator().selectionChanged()
    }
  }
}
