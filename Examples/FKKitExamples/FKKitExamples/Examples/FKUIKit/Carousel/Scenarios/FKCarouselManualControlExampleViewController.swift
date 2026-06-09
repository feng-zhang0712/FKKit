import FKUIKit
import UIKit

/// External prev/next controls and live scrollProgress readout.
final class FKCarouselManualControlExampleViewController: FKCarouselExampleScrollViewController, FKCarouselDelegate {
  private let carousel = FKCarousel(configuration: FKCarouselPresets.fullWidth(aspectRatio: 16.0 / 9.0))
  private let statusLabel = UILabel()
  private let progressLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Manual control"
    installScrollRootChrome()

    carousel.delegate = self
    carousel.pageProvider = { item, bounds in
      FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
    }
    carousel.setItems(FKCarouselExampleSupport.onboardingItems())

    statusLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    statusLabel.numberOfLines = 0

    progressLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    progressLabel.numberOfLines = 0

    let prev = FKCarouselExampleSupport.makeActionButton("Previous") { [weak self] in
      guard let self else { return }
      self.carousel.scrollToPage(self.carousel.currentPageIndex - 1, animated: true)
    }
    let next = FKCarouselExampleSupport.makeActionButton("Next") { [weak self] in
      guard let self else { return }
      self.carousel.scrollToPage(self.carousel.currentPageIndex + 1, animated: true)
    }
    let row = UIStackView(arrangedSubviews: [prev, next])
    row.axis = .horizontal
    row.spacing = 12
    row.distribution = .fillEqually

    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(row)
    contentStack.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(progressLabel)
    refreshStatus()
  }

  func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason) {
    refreshStatus(reason: reason)
  }

  func carousel(_ carousel: FKCarousel, didUpdateScrollProgress progress: CGFloat, fromPage: Int, toPage: Int) {
    progressLabel.text = String(
      format: "scrollProgress: %.2f · from %d → to %d · phase: %@",
      progress,
      fromPage,
      toPage,
      String(describing: carousel.stateSnapshot.phase)
    )
  }

  private func refreshStatus(reason: FKCarouselPageChangeReason? = nil) {
    statusLabel.text = """
    currentPageIndex: \(carousel.currentPageIndex)
    pageCount: \(carousel.pageCount)
    reason: \(reason.map { String(describing: $0) } ?? "—")
    """
  }
}
