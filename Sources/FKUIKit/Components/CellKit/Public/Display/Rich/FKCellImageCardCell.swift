import FKCoreKit
import UIKit

/// Full-width 16:9 image card with title and summary (D-27).
@MainActor
public final class FKCellImageCardCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellImageCardRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let imageHost = UIView()
  private let thumbnailView = FKCellImageThumbnailView()
  private let gradientView = UIView()
  private let titleLabel = UILabel()
  private let summaryLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()
  private var imageHeightConstraint: NSLayoutConstraint?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellImageCardConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellImageCardConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    thumbnailView.apply(content: configuration.image)
    titleLabel.text = configuration.title
    summaryLabel.text = configuration.summary

    groupedBackgroundHost.apply(nil, in: contentView)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .default
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellImageCardRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.resetForReuse()
    titleLabel.text = nil
    summaryLabel.text = nil
    selectionStyle = .default
    accessibilityLabel = nil
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    applyGradient()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .default
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    imageHost.translatesAutoresizingMaskIntoConstraints = false
    imageHost.clipsToBounds = true
    imageHost.layer.cornerRadius = 12
    imageHost.layer.cornerCurve = .continuous

    thumbnailView.translatesAutoresizingMaskIntoConstraints = false
    gradientView.translatesAutoresizingMaskIntoConstraints = false
    gradientView.isUserInteractionEnabled = false

    titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .boldSystemFont(ofSize: 17))
    titleLabel.numberOfLines = 2
    titleLabel.adjustsFontForContentSizeCategory = true

    summaryLabel.font = .preferredFont(forTextStyle: .subheadline)
    summaryLabel.textColor = .secondaryLabel
    summaryLabel.numberOfLines = 3
    summaryLabel.adjustsFontForContentSizeCategory = true

    separator.translatesAutoresizingMaskIntoConstraints = false
    imageHost.addSubview(thumbnailView)
    imageHost.addSubview(gradientView)
    rootStack.addArrangedSubview(imageHost)
    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(summaryLabel)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    imageHeightConstraint = imageHost.heightAnchor.constraint(
      equalTo: imageHost.widthAnchor,
      multiplier: 9.0 / 16.0
    )
    imageHeightConstraint?.isActive = true

    NSLayoutConstraint.activate([

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      thumbnailView.topAnchor.constraint(equalTo: imageHost.topAnchor),
      thumbnailView.leadingAnchor.constraint(equalTo: imageHost.leadingAnchor),
      thumbnailView.trailingAnchor.constraint(equalTo: imageHost.trailingAnchor),
      thumbnailView.bottomAnchor.constraint(equalTo: imageHost.bottomAnchor),

      gradientView.leadingAnchor.constraint(equalTo: imageHost.leadingAnchor),
      gradientView.trailingAnchor.constraint(equalTo: imageHost.trailingAnchor),
      gradientView.bottomAnchor.constraint(equalTo: imageHost.bottomAnchor),
      gradientView.heightAnchor.constraint(equalTo: imageHost.heightAnchor, multiplier: 0.45),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  private func applyGradient() {
    gradientView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
    let gradient = CAGradientLayer()
    gradient.frame = gradientView.bounds
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.35).cgColor]
    gradient.locations = [0, 1]
    gradientView.layer.addSublayer(gradient)
  }
}
