import FKCoreKit
import UIKit

/// Date picker form row with compact ``UIDatePicker`` (X-13, F-08).
@MainActor
public final class FKFormCellDateCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormDateRow

  /// Called on the main actor when the selected date changes.
  public var onDateChanged: ((Date) -> Void)?

  private let chromeView = FKFormDateTimeFieldChromeView()
  private var storedConfiguration = FKFormCellDateConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a date configuration with default appearance.
  public func apply(_ configuration: FKFormCellDateConfiguration) {
    apply(configuration, appearance: .default, date: chromeView.datePicker.date)
  }

  /// Applies a date configuration with explicit appearance and date value.
  public func apply(
    _ configuration: FKFormCellDateConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    date: Date = Date()
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    let picker = chromeView.datePicker
    picker.datePickerMode = .date
    picker.date = date
    picker.minimumDate = configuration.minimumDate
    picker.maximumDate = configuration.maximumDate
    picker.isEnabled = configuration.isEnabled

    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      trailingAccessory: .calendar,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isEnabled: configuration.isEnabled
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormDateRow) {
    apply(viewModel.configuration, date: viewModel.date)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onDateChanged = nil
    chromeView.datePicker.removeTarget(self, action: #selector(handleDateChanged), for: .valueChanged)
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    chromeView.datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    chromeView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chromeView)
    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: contentView.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      chromeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    chromeView.datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)

    let rowTap = UITapGestureRecognizer(target: self, action: #selector(handleRowTap))
    chromeView.addGestureRecognizer(rowTap)
  }

  @objc private func handleDateChanged() {
    onDateChanged?(chromeView.datePicker.date)
  }

  @objc private func handleRowTap() {
    guard storedConfiguration.isEnabled else { return }
    chromeView.datePicker.becomeFirstResponder()
  }
}
