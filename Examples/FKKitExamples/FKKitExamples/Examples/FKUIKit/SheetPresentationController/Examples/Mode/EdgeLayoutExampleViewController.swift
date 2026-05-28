import UIKit
import FKUIKit

/// Presents a left/right/top/bottom edge-attached tray using ``FKSheetPresentationConfiguration/Layout/edge(_:)``.
final class EdgeLayoutExampleViewController: FKSheetPresentationExamplePageViewController {
  private var edgeIndex: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Edge layout",
      subtitle: "Edge-attached trays for side panels and bottom drawers.",
      notes: """
      Edge layout fills one screen edge with a fixed panel frame.
      Detent APIs do not apply — use bottom/top sheet modes when you need resizable heights.
      """
    )

    addView(
      FKExampleControls.segmented(
        title: "Edge",
        items: ["Left", "Right", "Top", "Bottom"],
        selectedIndex: edgeIndex
      ) { [weak self] idx in
        self?.edgeIndex = idx
      }
    )

    addPrimaryButton(title: "Present edge tray") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.layout = .edge(self.selectedEdge)
      configuration.sheet.detents = [.fitContent]
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "Edge tray", configuration: configuration)
    }
  }

  private var selectedEdge: UIRectEdge {
    switch edgeIndex {
    case 0: return .left
    case 1: return .right
    case 2: return .top
    default: return .bottom
    }
  }
}
