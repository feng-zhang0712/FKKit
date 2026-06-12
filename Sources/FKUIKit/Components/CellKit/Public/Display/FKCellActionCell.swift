import FKCoreKit
import UIKit

/// Prominent action row for Shut Down, Offload, and similar settings actions (D-11).
@MainActor
public final class FKCellActionCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellActionRow

  private let layout = FKCellStandardRowLayout()
  private var titleCenterXConstraint: NSLayoutConstraint?
  private var titleLeadingConstraint: NSLayoutConstraint?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an action row configuration with default appearance.
  public func apply(_ configuration: FKCellActionConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies an action row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellActionConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)

    let titleColor: UIColor
    switch configuration.style {
    case .default:
      titleColor = appearance.linkColor.resolvedColor(with: traitCollection)
    case .destructive:
      titleColor = appearance.destructiveColor.resolvedColor(with: traitCollection)
    }
    layout.contentStack.setTitle(configuration.title, color: titleColor)
    layout.contentStack.titleLabel.textAlignment = configuration.alignment == .center ? .center : .natural
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(nil)
    layout.contentStack.setAccessoryViews([])

    updateTitleAlignment(configuration.alignment)

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
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKCellActionRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    layout.contentStack.titleLabel.textAlignment = .natural
    updateTitleAlignment(.leading)
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)

    titleCenterXConstraint = layout.contentStack.titleLabel.centerXAnchor.constraint(
      equalTo: layout.contentStack.centerXAnchor
    )
    titleLeadingConstraint = layout.contentStack.titleLabel.leadingAnchor.constraint(
      equalTo: layout.contentStack.leadingAnchor
    )
    titleLeadingConstraint?.isActive = true
  }

  private func updateTitleAlignment(_ alignment: FKCellActionAlignment) {
    switch alignment {
    case .center:
      titleLeadingConstraint?.isActive = false
      titleCenterXConstraint?.isActive = true
    case .leading:
      titleCenterXConstraint?.isActive = false
      titleLeadingConstraint?.isActive = true
    }
  }
}
