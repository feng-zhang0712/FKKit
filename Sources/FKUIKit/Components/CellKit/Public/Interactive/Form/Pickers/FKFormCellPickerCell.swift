import FKCoreKit
import UIKit

/// Read-only picker form row with dropdown or navigation presentation (X-11, X-12).
@MainActor
public final class FKFormCellPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormPickerRow

  /// Called on the main actor when the user taps the row to present selection UI.
  public var onTap: (() -> Void)?

  private let chromeView = FKFormTappableValueChromeView()
  private var storedConfiguration = FKFormCellPickerConfiguration()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a picker configuration with default appearance.
  public func apply(_ configuration: FKFormCellPickerConfiguration) {
    apply(configuration, appearance: .default, value: nil)
  }

  /// Applies a picker configuration with explicit appearance and selected value.
  public func apply(
    _ configuration: FKFormCellPickerConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    value: String? = nil
  ) {
    storedConfiguration = configuration

    chromeView.onTap = { [weak self] in
      guard let self, self.storedConfiguration.isEnabled else { return }
      self.onTap?()
    }
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      value: value,
      placeholder: configuration.placeholder,
      validation: configuration.validation,
      trailingAccessory: configuration.trailingAccessory,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isEnabled: configuration.isEnabled
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
    accessibilityTraits = configuration.isEnabled ? [.button] : [.notEnabled]
  }

  public func configure(with viewModel: FKFormPickerRow) {
    apply(viewModel.configuration, value: viewModel.value)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
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
  }
}
