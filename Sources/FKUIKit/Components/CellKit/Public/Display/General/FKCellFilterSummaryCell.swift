import FKCoreKit
import UIKit

/// Active filter chips with clear action (D-55).
@MainActor
public final class FKCellFilterSummaryCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellFilterSummaryRow

  /// Called on the main actor when the user taps clear.
  public var onClear: (() -> Void)?

  private let rowStack = UIStackView()
  private let chipGroup = FKChipGroup(selectionMode: .none)
  private let clearButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellFilterSummaryConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellFilterSummaryConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    chipGroup.chips = configuration.chipLabels.map {
      FKChipItem(id: $0, title: $0)
    }
    clearButton.isHidden = !configuration.showsClearButton
    clearButton.setTitle(configuration.clearButtonTitle, for: .normal)

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
  }

  public func configure(with viewModel: FKCellFilterSummaryRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onClear = nil
    chipGroup.chips = []
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 8
    rowStack.translatesAutoresizingMaskIntoConstraints = false

    chipGroup.translatesAutoresizingMaskIntoConstraints = false
    clearButton.translatesAutoresizingMaskIntoConstraints = false
    clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
    clearButton.setContentHuggingPriority(.required, for: .horizontal)

    rowStack.addArrangedSubview(chipGroup)
    rowStack.addArrangedSubview(clearButton)
    contentView.addSubview(rowStack)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
    ])
  }

  @objc private func handleClear() {
    onClear?()
  }
}
