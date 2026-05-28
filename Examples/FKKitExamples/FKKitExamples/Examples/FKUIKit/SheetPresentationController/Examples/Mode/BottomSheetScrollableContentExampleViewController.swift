import UIKit
import FKUIKit

/// Bottom sheet with scrollable content hosts (table, collection, or plain scroll view).
///
/// Key highlights:
/// - Uses `.bottomSheet` with automatic scroll/sheet pan handoff.
/// - Demonstrates the recommended layout: scroll views fill the sheet; static content uses top alignment.
final class BottomSheetScrollableContentExampleViewController: FKSheetPresentationExamplePageViewController {
  private enum ContentKind: Int {
    case table
    case collection
    case scrollView

    var title: String {
      switch self {
      case .table: return "Table view sheet"
      case .collection: return "Collection view sheet"
      case .scrollView: return "Scroll view sheet"
      }
    }
  }

  private var contentKindIndex = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Bottom sheet — Scrollable content",
      subtitle: "Table, collection, and scroll view inside a detented bottom sheet.",
      notes: """
      Scrollable hosts should fill the sheet bounds. Drag the grabber to resize; scroll inside the content without jitter.
      Try each content type below — automatic scroll tracking is enabled.
      """
    )

    addView(
      FKExampleControls.segmented(
        title: "Content host",
        items: ["Table view", "Collection", "Scroll view"],
        selectedIndex: contentKindIndex
      ) { [weak self] index in
        self?.contentKindIndex = index
      }
    )

    addPrimaryButton(title: "Present bottom sheet") { [weak self] in
      self?.presentBottomSheet()
    }
  }

  private func presentBottomSheet() {
    guard let kind = ContentKind(rawValue: contentKindIndex) else { return }

    let content: UIViewController = {
      switch kind {
      case .table:
        return FKExampleTableContentViewController(rowCount: 80)
      case .collection:
        return FKExampleCollectionContentViewController(itemCount: 60)
      case .scrollView:
        return FKExampleScrollListContentViewController(itemCount: 50)
      }
    }()
    content.title = kind.title

    var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
    configuration.sheet.detents = [.medium, .large, .full]
    configuration.sheet.scrollTrackingStrategy = .automatic

    FKSheetPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      delegate: nil,
      handlers: .init(),
      animated: true,
      completion: nil
    )
  }
}
