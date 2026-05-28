import UIKit

/// Right-hand ``UITableView`` section header used by ``FKFilterTwoColumnListViewController`` when
/// ``Configuration/rightSectionHeaderBehavior`` is not ``FKFilterTwoColumnRightSectionHeaderBehavior/standard``.
/// Mirrors ``FKFilterTwoColumnGridHeaderView`` tap + disclosure rules.
final class FKFilterTwoColumnListSectionHeaderView: UIView {
  private let titleLabel = UILabel()
  private let chevron = UIImageView()
  private let row = UIStackView()
  private var topConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  private var trailingConstraint: NSLayoutConstraint?
  private var tapAction: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 2
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    chevron.translatesAutoresizingMaskIntoConstraints = false
    chevron.tintColor = .secondaryLabel
    chevron.setContentHuggingPriority(.required, for: .horizontal)
    chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

    row.translatesAutoresizingMaskIntoConstraints = false
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 8
    row.isUserInteractionEnabled = false
    row.addArrangedSubview(titleLabel)
    row.addArrangedSubview(chevron)
    addSubview(row)

    topConstraint = row.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    bottomConstraint = row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
    leadingConstraint = row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
    trailingConstraint = row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
    NSLayoutConstraint.activate([
      topConstraint,
      bottomConstraint,
      leadingConstraint,
      trailingConstraint,
    ].compactMap { $0 })

    let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
    addGestureRecognizer(tap)
    isUserInteractionEnabled = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func apply(
    title: String,
    style: FKFilterTwoColumnListViewController.RightHeaderStyle,
    isHeaderSelectionHighlighted: Bool,
    isCollapsed: Bool,
    showsCollapseDisclosure: Bool,
    tapAction: (() -> Void)?
  ) {
    titleLabel.text = title
    titleLabel.font = style.font
    titleLabel.textColor = isHeaderSelectionHighlighted ? style.selectedTextColor : style.normalTextColor
    topConstraint?.constant = style.contentInsets.top
    bottomConstraint?.constant = -style.contentInsets.bottom
    leadingConstraint?.constant = style.contentInsets.left
    trailingConstraint?.constant = -style.contentInsets.right
    self.tapAction = tapAction

    if showsCollapseDisclosure {
      chevron.isHidden = false
      chevron.image = UIImage(
        systemName: isCollapsed ? "chevron.forward" : "chevron.down",
        withConfiguration: UIImage.SymbolConfiguration(scale: .small)
      )
    } else {
      chevron.isHidden = true
    }
  }

  @objc private func onTap() {
    tapAction?()
  }
}
