import FKCoreKit
import UIKit

/// Commerce product row with image, specs, and price (D-28).
@MainActor
public final class FKCellProductCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellProductRow

  private let layout = FKCellStandardRowLayout()
  private let imageHost = UIView()
  private let thumbnailView = FKCellImageThumbnailView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellProductConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellProductConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    thumbnailView.apply(content: configuration.image)
    layout.contentStack.setLeadingContent(imageHost, width: FKCellLayoutMetrics.productImageSize)
    layout.contentStack.setTitle(configuration.title, numberOfLines: 2)
    layout.contentStack.setSubtitle(configuration.specText)
    layout.contentStack.setDetail(configuration.price, emphasis: .primary)
    if let quantity = configuration.quantityText {
      layout.accessoryHost.apply(.value(quantity), appearance: appearance)
      layout.contentStack.setAccessoryViews([layout.accessoryHost])
    } else {
      layout.contentStack.setAccessoryViews([])
    }

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

  public func configure(with viewModel: FKCellProductRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.resetForReuse()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)

    imageHost.translatesAutoresizingMaskIntoConstraints = false
    thumbnailView.translatesAutoresizingMaskIntoConstraints = false
    imageHost.addSubview(thumbnailView)
    NSLayoutConstraint.activate([
      thumbnailView.topAnchor.constraint(equalTo: imageHost.topAnchor),
      thumbnailView.leadingAnchor.constraint(equalTo: imageHost.leadingAnchor),
      thumbnailView.trailingAnchor.constraint(equalTo: imageHost.trailingAnchor),
      thumbnailView.bottomAnchor.constraint(equalTo: imageHost.bottomAnchor),
      imageHost.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.productImageSize),
    ])
  }
}
