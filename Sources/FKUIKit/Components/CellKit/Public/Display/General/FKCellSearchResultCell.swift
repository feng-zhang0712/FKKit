import FKCoreKit
import UIKit

/// Search result row with query highlighting (D-66).
@MainActor
public final class FKCellSearchResultCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSearchResultRow

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellSearchResultConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellSearchResultConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    if let icon = configuration.leadingIcon {
      iconSlot.apply(icon)
      layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    } else {
      layout.contentStack.setLeadingContent(nil, width: 0)
    }

    let titleAttr = FKCellSearchHighlight.attributedString(
      text: configuration.title,
      query: configuration.query
    )
    layout.contentStack.titleLabel.attributedText = titleAttr
    layout.contentStack.titleLabel.isHidden = false

    if let subtitle = configuration.subtitle {
      let subtitleAttr = FKCellSearchHighlight.attributedString(
        text: subtitle,
        query: configuration.query,
        baseFont: .preferredFont(forTextStyle: .subheadline),
        baseColor: appearance.secondaryLabelColor
      )
      layout.contentStack.subtitleLabel.attributedText = subtitleAttr
      layout.contentStack.subtitleLabel.isHidden = false
    } else {
      layout.contentStack.subtitleLabel.attributedText = nil
      layout.contentStack.subtitleLabel.isHidden = true
    }

    layout.contentStack.setAccessoryViews([])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellSearchResultRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    layout.contentStack.titleLabel.attributedText = nil
    layout.contentStack.subtitleLabel.attributedText = nil
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
