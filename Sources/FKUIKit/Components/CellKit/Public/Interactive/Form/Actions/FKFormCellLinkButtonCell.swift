import FKCoreKit
import UIKit

/// Centered link-style ``FKButton`` row (X-51, F-10).
@MainActor
public final class FKFormCellLinkButtonCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormLinkButtonRow

  /// Called when the user taps the link button.
  public var onTap: (() -> Void)?

  private let button = FKButton()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellLinkButtonConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellLinkButtonConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    let linkColor = appearance.linkColor.resolvedColor(with: traitCollection)
    button.setTitle(
      FKButtonLabelConfiguration(text: configuration.title, font: .systemFont(ofSize: 17), color: linkColor),
      for: .normal
    )
    button.isEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.title
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKFormLinkButtonRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
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
      button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  @objc private func handleTap() {
    onTap?()
  }
}
