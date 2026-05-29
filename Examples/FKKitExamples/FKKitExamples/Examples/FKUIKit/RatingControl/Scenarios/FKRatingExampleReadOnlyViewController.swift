import FKUIKit
import UIKit

/// Read-only ratings for product summaries and review rows.
final class FKRatingExampleReadOnlyViewController: FKRatingExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Read-only"

    let summary = FKRatingControl.readOnlyStars(value: 4.5, itemCount: 5)
    summary.configuration.interaction.step = .half
    summary.configuration.layout.labelPlacement = .trailing
    summary.configuration.label.valuePrefix = "4.5 "
    summary.configuration.label.valueSuffix = " (128 reviews)"

    let summaryBox = FKRatingExampleSupport.sectionContainer(title: "Product header")
    summaryBox.addArrangedSubview(FKRatingExampleSupport.caption("Half-star readout with trailing caption — typical e-commerce pattern."))
    summaryBox.addArrangedSubview(FKRatingExampleSupport.embedRating(summary))
    contentStack.addArrangedSubview(summaryBox)

    let reviewsBox = FKRatingExampleSupport.sectionContainer(title: "Review rows")
    [
      ("Great quality", 5.0),
      ("Good but slow shipping", 3.5),
      ("Average", 2.0),
    ].forEach { title, score in
      reviewsBox.addArrangedSubview(makeReviewRow(title: title, score: score))
    }
    contentStack.addArrangedSubview(reviewsBox)
  }

  private func makeReviewRow(title: String, score: Double) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.numberOfLines = 0

    let stars = FKRatingControl.readOnlyStars(value: score, itemCount: 5)
    stars.configuration.interaction.step = .half
    stars.configuration.layout.itemSize = CGSize(width: 18, height: 18)
    stars.configuration.layout.itemSpacing = 2

    let row = UIStackView(arrangedSubviews: [titleLabel, FKRatingExampleSupport.embedRating(stars)])
    row.axis = .vertical
    row.spacing = 12
    row.isLayoutMarginsRelativeArrangement = true
    row.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 12, right: 0)
    return row
  }
}
