import FKCoreKit
import UIKit

/// Media list row with thumbnail, title, and optional duration badge (D-23).
@MainActor
public final class FKCellMediaThumbnailCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellMediaThumbnailRow

  private let layout = FKCellStandardRowLayout()
  private let thumbnailHost = UIView()
  private let thumbnailView = FKCellImageThumbnailView()
  private let durationLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellMediaThumbnailConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellMediaThumbnailConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    thumbnailView.apply(content: configuration.image)
    if let duration = configuration.durationBadge, !duration.isEmpty {
      durationLabel.text = duration
      durationLabel.isHidden = false
    } else {
      durationLabel.isHidden = true
    }

    layout.contentStack.setLeadingContent(thumbnailHost, width: FKCellLayoutMetrics.thumbnailSize)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews(configuration.showsDisclosure ? [layout.accessoryHost] : [])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellMediaThumbnailRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.resetForReuse()
    durationLabel.isHidden = true
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)

    thumbnailHost.translatesAutoresizingMaskIntoConstraints = false
    thumbnailView.translatesAutoresizingMaskIntoConstraints = false
    durationLabel.translatesAutoresizingMaskIntoConstraints = false
    durationLabel.font = .preferredFont(forTextStyle: .caption2)
    durationLabel.textColor = .white
    durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    durationLabel.layer.cornerRadius = 4
    durationLabel.layer.masksToBounds = true
    durationLabel.textAlignment = .center
    durationLabel.isHidden = true

    thumbnailHost.addSubview(thumbnailView)
    thumbnailHost.addSubview(durationLabel)
    NSLayoutConstraint.activate([
      thumbnailView.topAnchor.constraint(equalTo: thumbnailHost.topAnchor),
      thumbnailView.leadingAnchor.constraint(equalTo: thumbnailHost.leadingAnchor),
      thumbnailView.trailingAnchor.constraint(equalTo: thumbnailHost.trailingAnchor),
      thumbnailView.bottomAnchor.constraint(equalTo: thumbnailHost.bottomAnchor),
      thumbnailHost.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.thumbnailSize),

      durationLabel.trailingAnchor.constraint(equalTo: thumbnailHost.trailingAnchor, constant: -4),
      durationLabel.bottomAnchor.constraint(equalTo: thumbnailHost.bottomAnchor, constant: -4),
      durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
      durationLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
    ])
  }
}
