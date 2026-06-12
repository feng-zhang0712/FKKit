import FKCoreKit
import UIKit

/// Two-column regulatory disclosure with stacked content blocks (D-15).
@MainActor
public final class FKCellRegulatoryCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellRegulatoryRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let columnsRow = UIStackView()
  private let regionLabel = UILabel()
  private let contentStack = UIStackView()
  private let footerLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellRegulatoryConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellRegulatoryConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    regionLabel.text = configuration.regionTitle
    rebuildContentBlocks(configuration.contentBlocks)

    if let footer = configuration.footerMetadata, !footer.isEmpty {
      footerLabel.text = footer
      footerLabel.isHidden = false
    } else {
      footerLabel.isHidden = true
    }

    groupedBackgroundHost.apply(nil, in: contentView)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.regionTitle
  }

  public func configure(with viewModel: FKCellRegulatoryRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    regionLabel.text = nil
    footerLabel.text = nil
    footerLabel.isHidden = true
    contentStack.arrangedSubviews.forEach { view in
      contentStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    columnsRow.axis = .horizontal
    columnsRow.alignment = .top
    columnsRow.spacing = 12

    regionLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: 17))
    regionLabel.numberOfLines = 0
    regionLabel.adjustsFontForContentSizeCategory = true
    regionLabel.setContentHuggingPriority(.required, for: .horizontal)
    regionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    regionLabel.widthAnchor.constraint(equalToConstant: 88).isActive = true

    contentStack.axis = .vertical
    contentStack.spacing = 8
    contentStack.alignment = .fill

    footerLabel.font = .preferredFont(forTextStyle: .caption1)
    footerLabel.textColor = .secondaryLabel
    footerLabel.numberOfLines = 0
    footerLabel.isHidden = true

    separator.translatesAutoresizingMaskIntoConstraints = false
    columnsRow.addArrangedSubview(regionLabel)
    columnsRow.addArrangedSubview(contentStack)
    rootStack.addArrangedSubview(columnsRow)
    rootStack.addArrangedSubview(footerLabel)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  private func rebuildContentBlocks(_ blocks: [FKCellRegulatoryBlock]) {
    contentStack.arrangedSubviews.forEach { view in
      contentStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    for block in blocks {
      switch block {
      case let .text(text):
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        contentStack.addArrangedSubview(label)
      case let .image(content):
        let thumbnail = FKCellImageThumbnailView()
        thumbnail.apply(content: content)
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(thumbnail)
        thumbnail.heightAnchor.constraint(equalToConstant: 48).isActive = true
        thumbnail.widthAnchor.constraint(equalToConstant: 120).isActive = true
      case let .spacer(height):
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentStack.addArrangedSubview(spacer)
      }
    }
  }
}
