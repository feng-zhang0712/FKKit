import FKCoreKit
import UIKit

/// Slim inline notice banner row (D-56).
@MainActor
public final class FKCellInlineNoticeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellInlineNoticeRow

  /// Called on the main actor when the user taps the close button.
  public var onClose: (() -> Void)?

  private let bannerView = UIView()
  private let messageLabel = UILabel()
  private let closeButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellInlineNoticeConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellInlineNoticeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    messageLabel.text = configuration.message
    messageLabel.textColor = configuration.textColor
    bannerView.backgroundColor = configuration.backgroundColor
    closeButton.isHidden = !configuration.showsCloseButton

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = .none
    accessibilityLabel = configuration.message
  }

  public func configure(with viewModel: FKCellInlineNoticeRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onClose = nil
    messageLabel.text = nil
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    bannerView.translatesAutoresizingMaskIntoConstraints = false
    bannerView.layer.cornerRadius = 8
    bannerView.layer.cornerCurve = .continuous

    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.numberOfLines = 0
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.adjustsFontForContentSizeCategory = true

    closeButton.translatesAutoresizingMaskIntoConstraints = false
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    closeButton.accessibilityLabel = "Close"

    bannerView.addSubview(messageLabel)
    bannerView.addSubview(closeButton)
    contentView.addSubview(bannerView)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      bannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      messageLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 10),
      messageLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 12),
      messageLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -10),

      closeButton.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8),
      closeButton.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -8),
      closeButton.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 32),
      closeButton.heightAnchor.constraint(equalToConstant: 32),
    ])
  }

  @objc private func handleClose() {
    onClose?()
  }
}
