import FKCoreKit
import UIKit

/// Storage usage card with segmented progress and legend (D-13).
@MainActor
public final class FKCellStorageSummaryCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStorageSummaryRow

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let titleLabel = UILabel()
  private let usageLabel = UILabel()
  private let progressView = FKCellStorageProgressView()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellStorageSummaryConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellStorageSummaryConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    usageLabel.text = configuration.usageText
    progressView.apply(segments: configuration.segments, progress: configuration.progress)

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = "\(configuration.title). \(configuration.usageText)"
  }

  public func configure(with viewModel: FKCellStorageSummaryRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    usageLabel.text = nil
    progressView.apply(segments: [], progress: 0)
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
    titleLabel.adjustsFontForContentSizeCategory = true

    usageLabel.font = .preferredFont(forTextStyle: .footnote)
    usageLabel.textColor = .secondaryLabel
    usageLabel.adjustsFontForContentSizeCategory = true

    progressView.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false

    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(usageLabel)
    rootStack.addArrangedSubview(progressView)

    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
