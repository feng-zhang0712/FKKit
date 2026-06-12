import FKCoreKit
import UIKit

/// Vertical radio group using UIButton circle style until ``FKRadioGroup`` ships (X-37, F-06).
@MainActor
public final class FKFormCellRadioGroupCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormRadioGroupRow

  /// Called when the selected option changes.
  public var onSelectionChanged: ((String) -> Void)?

  private let rootStack = UIStackView()
  private let labelView = UILabel()
  private let optionsStack = UIStackView()
  private var optionButtons: [String: UIButton] = [:]
  private var selectedID: String?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellRadioGroupConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellRadioGroupConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    selectedID = configuration.selectedOptionID

    if let label = configuration.label, !label.isEmpty {
      labelView.text = label
      labelView.isHidden = false
    } else {
      labelView.isHidden = true
    }

    rebuildOptions(configuration.options, selectedID: configuration.selectedOptionID, isEnabled: configuration.isEnabled)

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormRadioGroupRow) {
    var configuration = viewModel.configuration
    configuration.selectedOptionID = viewModel.selectedOptionID
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSelectionChanged = nil
    selectedID = nil
    optionButtons.removeAll()
    optionsStack.arrangedSubviews.forEach { view in
      optionsStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    labelView.font = .preferredFont(forTextStyle: .footnote)
    labelView.textColor = .secondaryLabel
    labelView.isHidden = true

    optionsStack.axis = .vertical
    optionsStack.spacing = 8

    rootStack.addArrangedSubview(labelView)
    rootStack.addArrangedSubview(optionsStack)

    contentView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  private func rebuildOptions(_ options: [FKFormRadioOption], selectedID: String?, isEnabled: Bool) {
    optionsStack.arrangedSubviews.forEach { view in
      optionsStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    optionButtons.removeAll()

    for option in options {
      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.contentHorizontalAlignment = .leading
      button.titleLabel?.font = .preferredFont(forTextStyle: .body)
      button.setTitle("  \(option.title)", for: .normal)
      button.setTitleColor(.label, for: .normal)
      let isSelected = option.id == selectedID
      button.setImage(UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle"), for: .normal)
      button.tintColor = .systemBlue
      button.isEnabled = isEnabled
      button.accessibilityIdentifier = option.id
      button.addTarget(self, action: #selector(handleOptionTap(_:)), for: .touchUpInside)
      optionButtons[option.id] = button
      optionsStack.addArrangedSubview(button)
    }
  }

  @objc private func handleOptionTap(_ sender: UIButton) {
    guard let id = optionButtons.first(where: { $0.value === sender })?.key else { return }
    selectedID = id
    for (optionID, button) in optionButtons {
      let isSelected = optionID == id
      button.setImage(UIImage(systemName: isSelected ? "largecircle.fill.circle" : "circle"), for: .normal)
    }
    onSelectionChanged?(id)
  }
}
