import FKCoreKit
import UIKit

/// Embedded wheel picker with expandable height (X-67).
@MainActor
public final class FKFormCellInlineWheelCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellInlineWheelRow

  public var onSelectionChanged: ((Int, String) -> Void)?

  private let titleLabel = UILabel()
  private let pickerView = UIPickerView()
  private var options: [String] = []

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellInlineWheelConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellInlineWheelConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    options = configuration.options
    pickerView.reloadAllComponents()
    if !options.isEmpty {
      let index = min(max(configuration.selectedIndex, 0), options.count - 1)
      pickerView.selectRow(index, inComponent: 0, animated: false)
    }
    pickerView.isHidden = !configuration.isExpanded
    pickerView.isUserInteractionEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellInlineWheelRow) {
    var configuration = viewModel.configuration
    configuration.selectedIndex = viewModel.selectedIndex
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSelectionChanged = nil
    options = []
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    pickerView.dataSource = self
    pickerView.delegate = self

    contentView.addSubview(titleLabel)
    contentView.addSubview(pickerView)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    pickerView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      pickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      pickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      pickerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      pickerView.heightAnchor.constraint(equalToConstant: 216),
    ])
  }
}

extension FKFormCellInlineWheelCell: UIPickerViewDataSource, UIPickerViewDelegate {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    options.count
  }

  public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    options[row]
  }

  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    onSelectionChanged?(row, options[row])
  }
}
