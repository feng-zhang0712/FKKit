import FKCoreKit
import UIKit

/// Full-width primary submit button row (X-49, F-09).
@MainActor
public final class FKFormCellPrimaryButtonCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormPrimaryButtonRow

  /// Called on the main actor when the user taps the button.
  public var onTap: (() -> Void)?

  private let button = FKButton()
  private var storedConfiguration = FKFormCellPrimaryButtonConfiguration(title: "")

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a primary button configuration.
  public func apply(_ configuration: FKFormCellPrimaryButtonConfiguration) {
    storedConfiguration = configuration
    button.setTitle(
      FKButtonLabelConfiguration(text: configuration.title, font: .boldSystemFont(ofSize: 17), color: .white),
      for: .normal
    )
    button.isEnabled = configuration.isEnabled && !configuration.isLoading
    button.setLoading(configuration.isLoading)
    selectionStyle = .none
    accessibilityLabel = configuration.title
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKFormPrimaryButtonRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
    button.setLoading(false)
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    contentView.addSubview(button)

    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  @objc private func handleTap() {
    onTap?()
  }
}
