import FKCoreKit
import UIKit

/// Left-aligned link action row without chevron (D-10).
@MainActor
public final class FKCellLinkCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellLinkRow

  private let layout = FKCellStandardRowLayout()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a link row configuration with default appearance.
  public func apply(_ configuration: FKCellLinkConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a link row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellLinkConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(
      configuration.title,
      color: appearance.linkColor.resolvedColor(with: traitCollection)
    )
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(nil)
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

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
    accessibilityTraits = [.button, .link]
  }

  public func configure(with viewModel: FKCellLinkRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
