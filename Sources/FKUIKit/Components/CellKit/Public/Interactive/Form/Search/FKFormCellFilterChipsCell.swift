import FKCoreKit
import UIKit

/// Horizontal ``FKChipGroup`` filter row (X-30).
@MainActor
public final class FKFormCellFilterChipsCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormFilterChipsRow

  /// Called when chip selection changes.
  public var onSelectionChange: ((Set<String>) -> Void)?

  private let chipGroup = FKChipGroup(selectionMode: .single)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellFilterChipsConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellFilterChipsConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    chipGroup.selectionMode = configuration.selectionMode
    chipGroup.chips = configuration.chips
    chipGroup.setSelectedIDs(configuration.selectedIDs, animated: false)
    chipGroup.isUserInteractionEnabled = configuration.isEnabled
    chipGroup.alpha = configuration.isEnabled ? 1 : 0.5

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = "Filter chips"
  }

  public func configure(with viewModel: FKFormFilterChipsRow) {
    var configuration = viewModel.configuration
    configuration.selectedIDs = viewModel.selectedIDs
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSelectionChange = nil
    chipGroup.chips = []
    chipGroup.setSelectedIDs([], animated: false)
    selectionStyle = .none
    accessibilityLabel = nil
    wireChipCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    var config = FKChipGroup.defaultConfiguration
    config.layoutMode = .horizontalScroll
    chipGroup.configuration = config
    chipGroup.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(chipGroup)
    NSLayoutConstraint.activate([
      chipGroup.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      chipGroup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      chipGroup.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      chipGroup.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      chipGroup.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
    ])

    wireChipCallbacks()
  }

  private func wireChipCallbacks() {
    chipGroup.onSelectionChange = { [weak self] ids in
      self?.onSelectionChange?(ids)
    }
  }
}
