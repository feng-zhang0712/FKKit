import UIKit
import FKUIKit

/// Lazy page construction with preload range and retention policy controls.
@MainActor
final class FKPagingLazyPagesExampleViewController: UIViewController, FKPagingControllerDelegate {
  private let pagingController: FKPagingController
  private let statsLabel = UILabel()

  private static var instantiationCounter = 0

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(8)
    pagingController = FKPagingController(
      tabs: tabs,
      pageCount: 8,
      pageProvider: { index in
        Self.instantiationCounter += 1
        let hues: [CGFloat] = [0.55, 0.28, 0.08, 0.15, 0.75, 0.45, 0.95, 0.65]
        let hue = hues[index % hues.count]
        let color = UIColor(hue: hue, saturation: 0.55, brightness: 0.95, alpha: 1)
        return FKPagingDemoPageViewController(color: color, titleText: "Lazy #\(index)")
      },
      selectedIndex: 1,
      configuration: FKPagingConfiguration(
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1),
        gesturePolicy: .exclusive
      )
    )
    super.init(nibName: nil, bundle: nil)
    pagingController.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Lazy loading"
    view.backgroundColor = .systemBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    statsLabel.font = .preferredFont(forTextStyle: .footnote)
    statsLabel.textColor = .secondaryLabel
    statsLabel.numberOfLines = 0
    statsLabel.translatesAutoresizingMaskIntoConstraints = false
    refreshStatsText()
    view.addSubview(statsLabel)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      statsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      statsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      statsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func refreshStatsText() {
    statsLabel.text =
      "Instantiations: \(Self.instantiationCounter). Preload range keeps neighbors warm; keepNear removes distant controllers from the lazy cache."
  }

  func pagingController(_ controller: FKPagingController, didSettleAt _: Int) {
    refreshStatsText()
  }

  func pagingController(_ controller: FKPagingController, didChangePhase _: FKPagingPhase) {
    refreshStatsText()
  }
}
