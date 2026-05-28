import UIKit
import FKUIKit

/// Shows keyboard avoidance strategies for forms vs scrollable content.
///
/// Key highlights:
/// - Compare `.adjustContainer` (best for fixed forms) vs `.adjustContentInsets` (best for scroll views).
/// Caveat:
/// - Prefer `.adjustContentInsets` when your content is scrollable; it avoids “jumping” the entire container.
final class KeyboardAvoidanceExampleViewController: FKSheetPresentationExamplePageViewController {
  private var strategyIndex: Int = 0
  private var usesScrollView: Bool = true

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Keyboard avoidance",
      subtitle: "A practical must-have for real apps with text input.",
      notes: """
      Choose strategy:
      - adjustContainer: moves/resizes the whole container (often best for compact forms).
      - adjustContentInsets: keeps container stable and scrolls content (best for lists).
      - interactive: follows keyboard motion for chat-like experiences.
      """
    )

    addView(
      FKExampleControls.segmented(
        title: "Strategy",
        items: ["adjustContainer", "adjustContentInsets", "interactive"],
        selectedIndex: strategyIndex
      ) { [weak self] idx in
        self?.strategyIndex = idx
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Use scroll view content (recommended)",
        isOn: usesScrollView
      ) { [weak self] isOn in
        self?.usesScrollView = isOn
      }
    )

    addPrimaryButton(title: "Present form") { [weak self] in
      guard let self else { return }
      let content = FKExampleFormContentViewController(usesScrollView: self.usesScrollView)

      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fraction(0.55), .full]
      configuration.keyboardAvoidance.isEnabled = true
      configuration.keyboardAvoidance.strategy = switch self.strategyIndex {
      case 0: .adjustContainer
      case 1: .adjustContentInsets
      default: .interactive
      }

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
}

