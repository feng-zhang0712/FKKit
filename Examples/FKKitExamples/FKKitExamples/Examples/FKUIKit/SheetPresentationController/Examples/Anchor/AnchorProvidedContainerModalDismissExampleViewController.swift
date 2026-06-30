import UIKit
import FKUIKit

/// Exercises `.inProvidedContainer` anchor hosting across a full-screen modal present/dismiss cycle.
///
/// Mirrors tab-bar filter overlays: the anchor strip stays in a parent container while a search
/// (or similar) modal covers the screen. After dismiss, the anchor popup must stay flush with the strip.
final class AnchorProvidedContainerModalDismissExampleViewController: FKSheetPresentationExamplePageViewController {
  private let anchorStrip = UIView()
  private let anchorTitleLabel = UILabel()
  private var activePresentation: FKSheetPresentationController?

  override var pinnedTopView: UIView? { anchorStrip }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Provided Container + Modal"
    setupAnchorStrip()

    setHeader(
      title: "Provided Container + Modal Dismiss",
      subtitle: "Anchor popup hosted in the parent view; full-screen modal on top.",
      notes: "Expand the filter strip, tap Search in the navigation bar, then dismiss. The popup should stay attached with no gap or jump."
    )

    addView(
      FKExampleControls.infoLabel(
        text: "Uses `hostStrategy: .inProvidedContainer(view)` with the anchor strip pinned above the scroll content. Search stays in the navigation bar so it remains tappable while the popup is open."
      )
    )

    addPrimaryButton(title: "Toggle filter popup") { [weak self] in
      self?.toggleAnchorPresentation()
    }

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Search",
      style: .plain,
      target: self,
      action: #selector(presentSearchModal)
    )
  }

  private func setupAnchorStrip() {
    anchorStrip.backgroundColor = .secondarySystemGroupedBackground

    anchorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    anchorTitleLabel.text = "Filter strip (tap to expand)"
    anchorTitleLabel.font = .preferredFont(forTextStyle: .body)
    anchorTitleLabel.textColor = .label
    anchorStrip.addSubview(anchorTitleLabel)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleAnchorStripTap))
    anchorStrip.addGestureRecognizer(tap)
    anchorStrip.isUserInteractionEnabled = true

    NSLayoutConstraint.activate([
      anchorStrip.heightAnchor.constraint(equalToConstant: 52),
      anchorTitleLabel.leadingAnchor.constraint(equalTo: anchorStrip.leadingAnchor, constant: 16),
      anchorTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: anchorStrip.trailingAnchor, constant: -16),
      anchorTitleLabel.centerYAnchor.constraint(equalTo: anchorStrip.centerYAnchor),
    ])
  }

  @objc
  private func handleAnchorStripTap() {
    toggleAnchorPresentation()
  }

  private func toggleAnchorPresentation() {
    if let activePresentation {
      activePresentation.dismiss(animated: false) { [weak self] in
        self?.activePresentation = nil
      }
      return
    }

    let anchor = FKAnchor(
      sourceView: anchorStrip,
      edge: .bottom,
      direction: .down,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0
    )
    let anchorConfig = FKAnchorConfiguration(
      anchor: anchor,
      hostStrategy: .inProvidedContainer(FKWeakReference(view)),
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .belowAnchorOnly
    )

    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .anchor(anchorConfig)
    configuration.dismissBehavior = .init(allowsTapOutside: true, allowsSwipe: true, allowsBackdropTap: true)
    configuration.backdropStyle = .dim(color: .black, alpha: 0.25)
    configuration.cornerRadius = 12
    configuration.shadow = .custom(color: .black, opacity: 0.18, radius: 16, offset: CGSize(width: 0, height: 8))

    let content = FKExampleLabelContentViewController(text: "Filter options")
    content.preferredContentSize = .init(width: 0, height: 240)

    activePresentation = FKSheetPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      handlers: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      }),
      animated: false
    )
  }

  @objc
  private func presentSearchModal() {
    let search = SearchModalExampleViewController()
    search.modalPresentationStyle = .fullScreen
    let nav = UINavigationController(rootViewController: search)
    nav.modalPresentationStyle = .fullScreen
    present(nav, animated: false)
  }
}

private final class SearchModalExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = "Search"

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(closeTapped)
    )

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Full-screen search (dismiss to verify anchor alignment)"
    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .secondaryLabel
    view.addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  @objc
  private func closeTapped() {
    dismiss(animated: false)
  }
}
