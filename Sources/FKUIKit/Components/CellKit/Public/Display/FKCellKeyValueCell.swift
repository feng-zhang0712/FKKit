import FKCoreKit
import UIKit

/// Read-only key-value settings row (D-02, D-16).
@MainActor
public final class FKCellKeyValueCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellKeyValueRow

  private let layout = FKCellStandardRowLayout()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a key-value configuration with default appearance.
  public func apply(_ configuration: FKCellKeyValueConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a key-value configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellKeyValueConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(
      configuration.value,
      numberOfLines: configuration.valueNumberOfLines,
      emphasis: configuration.valueEmphasis
    )
    layout.contentStack.setAccessoryViews([])

    layout.applyChrome(
      .init(
        groupConfiguration: groupConfiguration,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    layout.contentStack.titleLabel.textColor = configuration.isEnabled ? .label : .tertiaryLabel
    selectionStyle = configuration.isSelectable && configuration.isEnabled ? .default : .none
    accessibilityLabel = "\(configuration.title), \(configuration.value)"
  }

  public func configure(with viewModel: FKCellKeyValueRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
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
