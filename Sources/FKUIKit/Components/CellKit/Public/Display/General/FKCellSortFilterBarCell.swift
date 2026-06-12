import FKCoreKit
import UIKit

/// Non-scrolling sort and filter action bar (D-78).
@MainActor
public final class FKCellSortFilterBarCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSortFilterBarRow

  /// Called on the main actor when the user taps sort.
  public var onSort: (() -> Void)?
  /// Called on the main actor when the user taps filter.
  public var onFilter: (() -> Void)?

  private let stack = UIStackView()
  private let sortButton = UIButton(type: .system)
  private let filterButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellSortFilterBarConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellSortFilterBarConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    sortButton.setTitle(configuration.sortTitle, for: .normal)
    filterButton.setTitle(configuration.filterTitle, for: .normal)
    sortButton.isHidden = !configuration.showsSort
    filterButton.isHidden = !configuration.showsFilter

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
  }

  public func configure(with viewModel: FKCellSortFilterBarRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSort = nil
    onFilter = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    sortButton.addTarget(self, action: #selector(handleSort), for: .touchUpInside)
    filterButton.addTarget(self, action: #selector(handleFilter), for: .touchUpInside)

    stack.addArrangedSubview(sortButton)
    stack.addArrangedSubview(filterButton)
    contentView.addSubview(stack)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      stack.heightAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.minimumRowHeight),
    ])
  }

  @objc private func handleSort() {
    onSort?()
  }

  @objc private func handleFilter() {
    onFilter?()
  }
}
