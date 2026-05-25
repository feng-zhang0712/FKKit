import UIKit

@MainActor
final class FKActionSheetCustomRowCell: UITableViewCell {
  private let hostView = UIView()
  private var hostHeightConstraint: NSLayoutConstraint?
  private var embeddedView: UIView?
  private var centerConstraints: [NSLayoutConstraint] = []
  private var leadingConstraints: [NSLayoutConstraint] = []

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    hostView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(hostView)
    NSLayoutConstraint.activate([
      hostView.topAnchor.constraint(equalTo: contentView.topAnchor),
      hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
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
      hostHeightConstraint?.isActive = false
      hostHeightConstraint = hostView.heightAnchor.constraint(equalToConstant: preferredHeight)
      hostHeightConstraint?.isActive = true
    } else {
      hostHeightConstraint?.isActive = false
      hostHeightConstraint = nil
    }

    if let embeddedView, let update = customRow.provider.update {
      update(context, embeddedView)
      applyEmbeddedLayout(alignment: appearance.rowAlignment, to: embeddedView)
    } else {
      embeddedView?.removeFromSuperview()
      let built = customRow.provider.build(context)
      embeddedView = built
      built.translatesAutoresizingMaskIntoConstraints = false
      hostView.addSubview(built)
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
        view.topAnchor.constraint(greaterThanOrEqualTo: hostView.topAnchor, constant: 10),
        view.bottomAnchor.constraint(lessThanOrEqualTo: hostView.bottomAnchor, constant: -10),
        view.centerYAnchor.constraint(equalTo: hostView.centerYAnchor),
        view.leadingAnchor.constraint(greaterThanOrEqualTo: hostView.leadingAnchor, constant: horizontalPadding),
        view.trailingAnchor.constraint(lessThanOrEqualTo: hostView.trailingAnchor, constant: -horizontalPadding),
        view.centerXAnchor.constraint(equalTo: hostView.centerXAnchor),
      ]
      NSLayoutConstraint.activate(centerConstraints)
    case .leading:
      leadingConstraints = [
        view.topAnchor.constraint(equalTo: hostView.topAnchor, constant: 10),
        view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor, constant: -10),
        view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: horizontalPadding),
        view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: -horizontalPadding),
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
    hostHeightConstraint?.isActive = false
    hostHeightConstraint = nil
  }
}
