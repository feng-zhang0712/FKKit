import FKCoreKit
import UIKit

/// Tag chips row for metadata display (D-54).
@MainActor
public final class FKCellTagCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellTagRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let titleLabel = UILabel()
  private let chipGroup = FKChipGroup(selectionMode: .none)
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellTagConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellTagConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    if let title = configuration.title, !title.isEmpty {
      titleLabel.text = title
      titleLabel.isHidden = false
    } else {
      titleLabel.isHidden = true
    }

    chipGroup.chips = configuration.chipLabels.map {
      FKChipItem(id: $0, title: $0)
    }

    groupedBackgroundHost.apply(nil, in: contentView)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
  }

  public func configure(with viewModel: FKCellTagRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    chipGroup.chips = []
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.isHidden = true

    chipGroup.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false

    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(chipGroup)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  private var appearance: FKCellAppearanceConfiguration = .default
}
