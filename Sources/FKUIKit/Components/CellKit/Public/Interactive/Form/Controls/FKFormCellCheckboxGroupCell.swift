import FKCoreKit
import UIKit

/// Vertical checkbox group using UIButton checkbox style (X-36).
@MainActor
public final class FKFormCellCheckboxGroupCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCheckboxGroupRow

  /// Called when an option checked state changes.
  public var onOptionChanged: ((String, Bool) -> Void)?

  private let rootStack = UIStackView()
  private let labelView = UILabel()
  private let optionsStack = UIStackView()
  private var optionButtons: [String: UIButton] = [:]

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellCheckboxGroupConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellCheckboxGroupConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    if let label = configuration.label, !label.isEmpty {
      labelView.text = label
      labelView.isHidden = false
    } else {
      labelView.isHidden = true
    }

    rebuildOptions(configuration.options, isEnabled: configuration.isEnabled)

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCheckboxGroupRow) {
    var configuration = viewModel.configuration
    configuration.options = viewModel.options
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onOptionChanged = nil
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

  private func rebuildOptions(_ options: [FKFormCheckboxOption], isEnabled: Bool) {
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
      button.setImage(UIImage(systemName: option.isChecked ? "checkmark.square.fill" : "square"), for: .normal)
      button.tintColor = .systemBlue
      button.isEnabled = isEnabled
      button.tag = option.id.hashValue
      button.accessibilityIdentifier = option.id
      button.addTarget(self, action: #selector(handleOptionTap(_:)), for: .touchUpInside)
      optionButtons[option.id] = button
      optionsStack.addArrangedSubview(button)
    }
  }

  @objc private func handleOptionTap(_ sender: UIButton) {
    guard let id = optionButtons.first(where: { $0.value === sender })?.key else { return }
    sender.isSelected.toggle()
    let isChecked = sender.currentImage == UIImage(systemName: "checkmark.square.fill")
    let newChecked = !isChecked
    sender.setImage(UIImage(systemName: newChecked ? "checkmark.square.fill" : "square"), for: .normal)
    onOptionChanged?(id, newChecked)
  }
}
