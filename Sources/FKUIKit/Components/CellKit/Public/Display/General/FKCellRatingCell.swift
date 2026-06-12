import FKCoreKit
import UIKit

/// Read-only star rating row with optional review count (D-52).
@MainActor
public final class FKCellRatingCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellRatingRow

  private let layout = FKCellStandardRowLayout()
  private let ratingControl = FKRatingControl()
  private let reviewLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellRatingConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellRatingConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    ratingControl.configuration.layout.itemCount = configuration.maxRating
    ratingControl.setValue(configuration.rating, animated: false, sendsControlEvents: false)

    if let reviews = configuration.reviewCountText {
      reviewLabel.text = reviews
      reviewLabel.isHidden = false
    } else {
      reviewLabel.isHidden = true
    }

    let accessoryStack = UIStackView(arrangedSubviews: [ratingControl, reviewLabel])
    accessoryStack.axis = .horizontal
    accessoryStack.spacing = 8
    accessoryStack.alignment = .center

    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(nil)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setAccessoryViews([accessoryStack])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = .none
    accessibilityLabel = "Rating \(configuration.rating)"
  }

  public func configure(with viewModel: FKCellRatingRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    reviewLabel.text = nil
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    reviewLabel.font = .preferredFont(forTextStyle: .footnote)
    reviewLabel.textColor = .secondaryLabel
    reviewLabel.adjustsFontForContentSizeCategory = true

    ratingControl.configuration.interaction.mode = .readOnly
    layout.install(in: contentView)
  }
}
