import FKCoreKit
import UIKit

/// Informational tip row with leading glyph (D-57).
@MainActor
public final class FKCellTipCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellTipRow

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

  public func apply(_ configuration: FKCellTipConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellTipConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(FKCellIconContent(symbolName: "info.circle"))
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.text, numberOfLines: 0)
    layout.contentStack.titleLabel.font = .preferredFont(forTextStyle: .footnote)
    layout.contentStack.titleLabel.textColor = appearance.secondaryLabelColor
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

    selectionStyle = .none
    accessibilityLabel = configuration.text
  }

  public func configure(with viewModel: FKCellTipRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
  }
}
