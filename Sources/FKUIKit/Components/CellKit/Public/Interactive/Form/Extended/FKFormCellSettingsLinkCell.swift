import FKCoreKit
import UIKit

/// Permission guidance with a link to open Settings (X-71).
@MainActor
public final class FKFormCellSettingsLinkCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellSettingsLinkRow

  /// Called when the user taps the settings link.
  public var onLinkTap: (() -> Void)?

  private let bodyLabel = UILabel()
  private let linkButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSettingsLinkConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellSettingsLinkConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    bodyLabel.text = configuration.body
    linkButton.setTitle(configuration.linkTitle, for: .normal)
    linkButton.setTitleColor(appearance.linkColor, for: .normal)
    linkButton.isEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.body
  }

  public func configure(with viewModel: FKFormCellSettingsLinkRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onLinkTap = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    bodyLabel.font = .preferredFont(forTextStyle: .footnote)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.numberOfLines = 0

    linkButton.contentHorizontalAlignment = .leading
    linkButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    linkButton.addTarget(self, action: #selector(handleLinkTap), for: .touchUpInside)

    contentView.addSubview(bodyLabel)
    contentView.addSubview(linkButton)
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    linkButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      bodyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      linkButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
      linkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      linkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      linkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  @objc private func handleLinkTap() {
    onLinkTap?()
  }
}
