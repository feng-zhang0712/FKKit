import UIKit
import FKUIKit

/// Demonstrates replacing anchor popup content while already presented.
///
/// Compares:
/// - ``FKSheetPresentationAnchorReplacementPolicy/dismissThenPresent(dismissAnimated:presentAnimated:)``
/// - ``FKSheetPresentationAnchorReplacementPolicy/replaceInPlace(contentTransition:animateLayout:layoutAnimationDuration:)``
final class AnchorContentReplacementExampleViewController: FKSheetPresentationExamplePageViewController {
  private enum MenuKind: Int {
    case short
    case long

    var title: String {
      switch self {
      case .short: return "Short menu"
      case .long: return "Long menu"
      }
    }

    var height: CGFloat {
      switch self {
      case .short: return 180
      case .long: return 360
      }
    }
  }

  private let anchorBar = UIView()
  private let anchorLabel = UILabel()
  private var policyIndex = 1
  private var nextMenu: MenuKind = .short
  private var activePresentation: FKSheetPresentationController?
  private let contentHost = FKSheetPresentationAnchorContentHostViewController()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Anchor content replacement",
      subtitle: "Switch popup content/height from the same anchor while presented.",
      notes: """
      Use the navigation bar Present / Switch actions while a popup is open (body controls are behind the mask).
      `replaceInPlace` keeps the shell visible (like FKAnchoredDropdownController tab switches).
      `dismissThenPresent` dismisses first, then presents the new content with independent animation flags.
      """
    )

    setupAnchorBar()

    addView(
      FKExampleControls.segmented(
        title: "Replacement policy",
        items: ["Dismiss then present", "Replace in place"],
        selectedIndex: policyIndex
      ) { [weak self] index in
        self?.policyIndex = index
      }
    )

    setupNavigationBarActions()
  }

  private func setupNavigationBarActions() {
    let presentItem = UIBarButtonItem(
      title: "Present",
      primaryAction: UIAction { [weak self] _ in
        self?.presentMenu(.short, isInitial: true)
      }
    )
    let switchItem = UIBarButtonItem(
      title: "Switch",
      primaryAction: UIAction { [weak self] _ in
        self?.switchMenu()
      }
    )
    navigationItem.rightBarButtonItems = [switchItem, presentItem]
  }

  override var pinnedTopView: UIView? { anchorBar }

  private func setupAnchorBar() {
    anchorBar.translatesAutoresizingMaskIntoConstraints = false
    anchorBar.backgroundColor = .secondarySystemGroupedBackground

    anchorLabel.translatesAutoresizingMaskIntoConstraints = false
    anchorLabel.font = .preferredFont(forTextStyle: .headline)
    anchorLabel.text = "Anchor bar (popup attaches here)"
    anchorBar.addSubview(anchorLabel)

    NSLayoutConstraint.activate([
      anchorLabel.leadingAnchor.constraint(equalTo: anchorBar.leadingAnchor, constant: 16),
      anchorLabel.trailingAnchor.constraint(equalTo: anchorBar.trailingAnchor, constant: -16),
      anchorLabel.topAnchor.constraint(equalTo: anchorBar.topAnchor, constant: 12),
      anchorLabel.bottomAnchor.constraint(equalTo: anchorBar.bottomAnchor, constant: -12),
      anchorBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
    ])
  }

  private func makeConfiguration() -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .anchor(
      FKAnchorConfiguration(
        anchor: FKAnchor(
          sourceView: anchorBar,
          edge: .bottom,
          direction: .down,
          alignment: .fill,
          widthPolicy: .matchContainer,
          offset: 0
        ),
        maskCoveragePolicy: .belowAnchorOnly
      )
    )
    configuration.backdropStyle = .dim(alpha: 0.28)
    configuration.cornerRadius = 12
    return configuration
  }

  private func makeMenuContent(_ menu: MenuKind) -> UIViewController {
    let content = FKExampleLabelContentViewController(text: menu.title)
    content.preferredContentSize = CGSize(width: 0, height: menu.height)
    return content
  }

  private func presentMenu(_ menu: MenuKind, isInitial: Bool) {
    let configuration = makeConfiguration()
    contentHost.setContent(makeMenuContent(menu), transition: .none, completion: nil)
    nextMenu = menu == .short ? .long : .short

    let controller = FKSheetPresentationController(
      contentController: contentHost,
      configuration: configuration,
      handlers: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      })
    )
    activePresentation = controller
    controller.present(from: self, animated: isInitial, completion: nil)
  }

  private func switchMenu() {
    let menu = nextMenu
    nextMenu = menu == .short ? .long : .short

    guard let controller = activePresentation else {
      presentMenu(menu, isInitial: true)
      return
    }

    switch policyIndex {
    case 0:
      contentHost.setContent(makeMenuContent(menu), transition: .none, completion: nil)
      controller.presentOrReplaceAnchorContent(
        from: self,
        contentController: contentHost,
        replacement: .dismissThenPresent(dismissAnimated: true, presentAnimated: true),
        presentAnimated: true,
        completion: nil
      )
    default:
      controller.presentOrReplaceAnchorContent(
        from: self,
        contentController: makeMenuContent(menu),
        replacement: .replaceInPlace(
          contentTransition: .crossfade(duration: 0.18),
          animateLayout: true,
          layoutAnimationDuration: 0.24
        ),
        presentAnimated: true,
        completion: nil
      )
    }
  }
}
