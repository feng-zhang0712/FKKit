import FKCoreKit
import UIKit

/// Dashed upload drop zone with tap-to-pick (X-62).
@MainActor
public final class FKFormCellDragUploadCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellDragUploadRow

  public var onTap: (() -> Void)?

  private let dropZone = UIView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellDragUploadConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellDragUploadConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    if let subtitle = configuration.subtitle {
      subtitleLabel.text = subtitle
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.isHidden = true
    }
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.title
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKFormCellDragUploadRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTap = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    dropZone.layer.cornerRadius = 10
    dropZone.layer.borderWidth = 1.5
    dropZone.layer.borderColor = UIColor.separator.cgColor
    dropZone.backgroundColor = .secondarySystemGroupedBackground
    dropZone.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    stack.axis = .vertical
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    dropZone.addSubview(stack)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    dropZone.addGestureRecognizer(tap)

    contentView.addSubview(dropZone)
    NSLayoutConstraint.activate([
      dropZone.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      dropZone.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      dropZone.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      dropZone.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      dropZone.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
      stack.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: dropZone.centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: dropZone.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: dropZone.trailingAnchor, constant: -16),
    ])
  }

  @objc private func handleTap() {
    onTap?()
  }
}
