import FKCoreKit
import UIKit

/// Vertical stack of key-value pairs for checkout summaries (D-29).
@MainActor
public final class FKCellStackedKeyValueCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStackedKeyValueRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let stack = UIStackView()
  private let separator = FKCellSeparatorLayout.makeDivider()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellStackedKeyValueConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellStackedKeyValueConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    stack.arrangedSubviews.forEach {
      stack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    for entry in configuration.entries {
      let row = UIStackView()
      row.axis = .horizontal
      row.distribution = .fill
      row.spacing = 8

      let titleLabel = UILabel()
      titleLabel.font = .preferredFont(forTextStyle: .body)
      titleLabel.textColor = .label
      titleLabel.text = entry.title
      titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

      let valueLabel = UILabel()
      valueLabel.font = .preferredFont(forTextStyle: .body)
      valueLabel.textColor = entry.valueEmphasis == .secondary
        ? appearance.secondaryLabelColor
        : .label
      valueLabel.text = entry.value
      valueLabel.textAlignment = .right
      valueLabel.numberOfLines = 0

      row.addArrangedSubview(titleLabel)
      row.addArrangedSubview(valueLabel)
      stack.addArrangedSubview(row)
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

  public func configure(with viewModel: FKCellStackedKeyValueRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    stack.arrangedSubviews.forEach {
      stack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)
    contentView.addSubview(separator)

    let insets = appearance.contentInsets
    NSLayoutConstraint.activate([

      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
