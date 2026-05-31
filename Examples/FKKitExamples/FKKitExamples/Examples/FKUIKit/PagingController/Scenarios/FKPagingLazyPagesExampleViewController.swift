import UIKit
import FKUIKit

/// Lazy page construction, preload/retention, lifecycle callbacks, and ``invalidatePage(at:)``.
@MainActor
final class FKPagingLazyPagesExampleViewController: UIViewController, FKPagingControllerDelegate {
  private let pagingController: FKPagingController
  private let statsLabel = UILabel()
  private let logView = FKPagingDemoSupport.makeLogTextView()

  private static var instantiationCounter = 0

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(6)
    pagingController = FKPagingController(
      tabs: tabs,
      pageCount: 6,
      pageProvider: { index in
        Self.instantiationCounter += 1
        let hues: [CGFloat] = [0.55, 0.28, 0.08, 0.15, 0.75, 0.45]
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
    title = "Lazy pages & lifecycle"
    view.backgroundColor = .systemGroupedBackground

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

    logView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(logView)

    let invalidateButton = FKTabBarExampleSupport.actionButton("Invalidate current page") { [weak self] in
      guard let self else { return }
      let index = pagingController.selectedIndex
      pagingController.invalidatePage(at: index)
      FKPagingDemoSupport.appendLog("invalidatePage(at: \(index))", to: logView)
      refreshStatsText()
    }
    invalidateButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(invalidateButton)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.52),

      statsLabel.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor, constant: 8),
      statsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      statsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

      logView.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: invalidateButton.topAnchor, constant: -8),

      invalidateButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      invalidateButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      invalidateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    FKPagingDemoSupport.appendLog(
      "Lifecycle: willDisplay → didDisplay on visibility; didEndDisplaying only after display (preload eviction is silent).",
      to: logView
    )
  }

  private func refreshStatsText() {
    statsLabel.text =
      "Instantiations: \(Self.instantiationCounter). Preload keeps neighbors warm; keepNear evicts distant pages."
  }

  func pagingController(_ controller: FKPagingController, didSettleAt _: Int) {
    refreshStatsText()
  }

  func pagingController(_ controller: FKPagingController, didChangePhase _: FKPagingPhase) {
    refreshStatsText()
  }

  func pagingController(_ controller: FKPagingController, willDisplayPage viewController: UIViewController, at index: Int) {
    FKPagingDemoSupport.appendLog("willDisplay @\(index)", to: logView)
  }

  func pagingController(_ controller: FKPagingController, didDisplayPage viewController: UIViewController, at index: Int) {
    FKPagingDemoSupport.appendLog("didDisplay @\(index)", to: logView)
    refreshStatsText()
  }

  func pagingController(_ controller: FKPagingController, didEndDisplayingPage viewController: UIViewController, at index: Int) {
    FKPagingDemoSupport.appendLog("didEndDisplaying @\(index)", to: logView)
    refreshStatsText()
  }
}
