import UIKit

/// Grouped card chrome with optional full-width separator for rich settings rows.
@MainActor
final class FKCellRichCardChromeView: UIView {
  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  let contentStack = UIStackView()
  let footerSeparator = FKCellSeparatorLayout.makeDivider()
  let footerButton = UIButton(type: .system)

  private var appearance: FKCellAppearanceConfiguration = .default

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func applyAppearance(_ appearance: FKCellAppearanceConfiguration) {
    self.appearance = appearance
  }

  func applyChrome(
    separatorPolicy: FKCellSeparatorPolicy,
    isLastInSection: Bool,
    to cell: UITableViewCell
  ) {
    groupedBackgroundHost.apply(nil, in: self)
    FKCellSeparatorLayout.updateVisibility(
      divider: footerSeparator,
      policy: separatorPolicy,
      isLastInSection: isLastInSection
    )
    cell.backgroundColor = appearance.groupedBackgroundColor
    cell.contentView.backgroundColor = appearance.groupedBackgroundColor
  }

  func setFooterAction(_ action: FKCellActionLink?, showsSeparator: Bool) {
    if let action {
      footerButton.setTitle(action.title, for: .normal)
      footerButton.isHidden = false
      footerSeparator.isHidden = !showsSeparator
    } else {
      footerButton.setTitle(nil, for: .normal)
      footerButton.isHidden = true
      footerSeparator.isHidden = true
    }
  }

  func resetForReuse() {
    groupedBackgroundHost.detach()
    contentStack.arrangedSubviews.forEach { view in
      contentStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    footerButton.setTitle(nil, for: .normal)
    footerButton.isHidden = true
    footerSeparator.isHidden = true
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    footerSeparator.translatesAutoresizingMaskIntoConstraints = false
    footerButton.translatesAutoresizingMaskIntoConstraints = false
    footerButton.contentHorizontalAlignment = .leading
    footerButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    footerButton.isHidden = true
    footerSeparator.isHidden = true
    addSubview(contentStack)
    addSubview(footerSeparator)
    addSubview(footerButton)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      contentStack.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
      contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
      contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),

      footerSeparator.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 12),
      footerSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
      footerSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),

      footerButton.topAnchor.constraint(equalTo: footerSeparator.bottomAnchor, constant: 12),
      footerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
      footerButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
      footerButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
    ])
  }
}
