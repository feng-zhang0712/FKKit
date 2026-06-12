import FKCoreKit
import UIKit
@MainActor
public final class FKCellReviewCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellReviewRow
  private let avatarSlot = FKCellAvatarSlotView()
  private let ratingControl = FKRatingControl()
  private let authorLabel = UILabel()
  private let excerptLabel = UILabel()
  private let timestampLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellReviewConfiguration) { apply(configuration, appearance: .default, imageURL: nil, image: nil) }
  public func apply(_ configuration: FKCellReviewConfiguration, appearance: FKCellAppearanceConfiguration = .default, imageURL: URL? = nil, image: UIImage? = nil) {
    avatarSlot.apply(configuration: configuration.avatarConfiguration, displayName: configuration.authorName, imageURL: imageURL, image: image)
    authorLabel.text = configuration.authorName
    excerptLabel.text = configuration.excerpt
    ratingControl.configuration.layout.itemCount = configuration.maxRating
    ratingControl.setValue(configuration.rating, animated: false, sendsControlEvents: false)
    if let ts = configuration.timestamp { timestampLabel.text = ts; timestampLabel.isHidden = false } else { timestampLabel.isHidden = true }
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.authorName
  }
  public func configure(with viewModel: FKCellReviewRow) { apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image) }
  public override func prepareForReuse() { super.prepareForReuse(); avatarSlot.resetForReuse(); authorLabel.text = nil; excerptLabel.text = nil; timestampLabel.text = nil; selectionStyle = .default }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear
    let header = UIStackView(arrangedSubviews: [authorLabel, ratingControl, timestampLabel])
    header.axis = .horizontal; header.spacing = 8; header.alignment = .center
    authorLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
    excerptLabel.font = .preferredFont(forTextStyle: .subheadline); excerptLabel.textColor = .secondaryLabel; excerptLabel.numberOfLines = +2
    timestampLabel.font = .preferredFont(forTextStyle: .caption1); timestampLabel.textColor = .tertiaryLabel
    let col = UIStackView(arrangedSubviews: [header, excerptLabel]); col.axis = .vertical; col.spacing = 4
    let root = UIStackView(arrangedSubviews: [avatarSlot, col]); root.axis = .horizontal; root.spacing = 12; root.alignment = .top
    root.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(root); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      avatarSlot.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),
      avatarSlot.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),
      root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      separator.leadingAnchor.constraint(equalTo: authorLabel.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
private extension UIFont { func withWeight(_ w: UIFont.Weight) -> UIFont { UIFont(descriptor: fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: w]]), size: pointSize) } }
