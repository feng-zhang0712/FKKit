import FKCoreKit
import UIKit

/// Time picker form row with compact ``UIDatePicker`` (X-14, F-08).
@MainActor
public final class FKFormCellTimeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormTimeRow

  /// Called on the main actor when the selected time changes.
  public var onTimeChanged: ((Date) -> Void)?

  private let chromeView = FKFormDateTimeFieldChromeView()
  private var storedConfiguration = FKFormCellTimeConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a time configuration with default appearance.
  public func apply(_ configuration: FKFormCellTimeConfiguration) {
    apply(configuration, appearance: .default, time: chromeView.datePicker.date)
  }

  /// Applies a time configuration with explicit appearance and time value.
  public func apply(
    _ configuration: FKFormCellTimeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    time: Date = Date()
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    let picker = chromeView.datePicker
    picker.datePickerMode = .time
    picker.date = time
    picker.minimumDate = configuration.minimumDate
    picker.maximumDate = configuration.maximumDate
    picker.isEnabled = configuration.isEnabled

    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      trailingAccessory: .clock,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isEnabled: configuration.isEnabled
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormTimeRow) {
    apply(viewModel.configuration, time: viewModel.time)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTimeChanged = nil
    chromeView.datePicker.removeTarget(self, action: #selector(handleTimeChanged), for: .valueChanged)
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    chromeView.datePicker.addTarget(self, action: #selector(handleTimeChanged), for: .valueChanged)
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

    chromeView.datePicker.addTarget(self, action: #selector(handleTimeChanged), for: .valueChanged)

    let rowTap = UITapGestureRecognizer(target: self, action: #selector(handleRowTap))
    chromeView.addGestureRecognizer(rowTap)
  }

  @objc private func handleTimeChanged() {
    onTimeChanged?(chromeView.datePicker.date)
  }

  @objc private func handleRowTap() {
    guard storedConfiguration.isEnabled else { return }
    chromeView.datePicker.becomeFirstResponder()
  }
}
