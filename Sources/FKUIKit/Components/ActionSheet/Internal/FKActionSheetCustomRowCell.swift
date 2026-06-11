import UIKit

/// Hosts integrator-built custom row content with optional fixed height.
@MainActor
final class FKActionSheetCustomRowCell: UITableViewCell {
  static let defaultReuseIdentifier = "FKActionSheetCustomRow"
  private var contentHeightConstraint: NSLayoutConstraint?
  private var embeddedView: UIView?
  private var centerConstraints: [NSLayoutConstraint] = []
  private var leadingConstraints: [NSLayoutConstraint] = []

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default
    backgroundColor = .clear
    contentView.backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    action: FKActionSheetAction,
    customRow: FKActionSheetCustomRow,
    context: FKActionSheetRowBuildContext,
    appearance: FKActionSheetAppearance
  ) {
    let selected = UIView()
    selected.backgroundColor = appearance.rowHighlightColor
    selectedBackgroundView = selected

    isUserInteractionEnabled = action.isEnabled && customRow.isSelectable

    if let label = action.accessibilityLabel {
      accessibilityLabel = label
    } else {
      accessibilityLabel = nil
    }
    accessibilityHint = action.accessibilityHint
    accessibilityTraits = customRow.isSelectable ? .button : .staticText

    if let preferredHeight = customRow.preferredHeight {
      contentHeightConstraint?.isActive = false
      contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: preferredHeight)
      contentHeightConstraint?.isActive = true
    } else {
      contentHeightConstraint?.isActive = false
      contentHeightConstraint = nil
    }

    if let embeddedView, let update = customRow.provider.update {
      update(context, embeddedView)
      applyEmbeddedLayout(alignment: appearance.rowAlignment, to: embeddedView)
    } else {
      embeddedView?.removeFromSuperview()
      NSLayoutConstraint.deactivate(centerConstraints + leadingConstraints)
      centerConstraints = []
      leadingConstraints = []

      let built = customRow.provider.build(context)
      embeddedView = built
      built.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(built)
      applyEmbeddedLayout(alignment: appearance.rowAlignment, to: built)
    }
  }

  private func applyEmbeddedLayout(alignment: FKActionSheetRowAlignment, to view: UIView) {
    NSLayoutConstraint.deactivate(centerConstraints + leadingConstraints)
    centerConstraints = []
    leadingConstraints = []

    let horizontalPadding = CGFloat(16)
    switch alignment {
    case .center:
      centerConstraints = [
        view.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
        view.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
        view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        view.leadingAnchor.constraint(
          greaterThanOrEqualTo: contentView.leadingAnchor,
          constant: horizontalPadding
        ),
        view.trailingAnchor.constraint(
          lessThanOrEqualTo: contentView.trailingAnchor,
          constant: -horizontalPadding
        ),
        view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      ]
      NSLayoutConstraint.activate(centerConstraints)
    case .leading:
      leadingConstraints = [
        view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
      ]
      NSLayoutConstraint.activate(leadingConstraints)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NSLayoutConstraint.deactivate(centerConstraints + leadingConstraints)
    centerConstraints = []
    leadingConstraints = []
    embeddedView?.removeFromSuperview()
    embeddedView = nil
    contentHeightConstraint?.isActive = false
    contentHeightConstraint = nil
  }
}
