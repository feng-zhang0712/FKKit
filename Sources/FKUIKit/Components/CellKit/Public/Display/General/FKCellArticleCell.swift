import FKCoreKit
import UIKit

/// News or article feed row with optional thumbnail (D-25).
@MainActor
public final class FKCellArticleCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellArticleRow

  private let layout = FKCellStandardRowLayout()
  private let thumbnailView = FKCellImageThumbnailView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellArticleConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellArticleConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    if let thumbnail = configuration.thumbnail {
      thumbnailView.apply(content: thumbnail)
      layout.contentStack.setLeadingContent(thumbnailView, width: FKCellLayoutMetrics.articleThumbnailWidth)
    } else {
      layout.contentStack.setLeadingContent(nil, width: 0)
    }
    layout.contentStack.setTitle(configuration.title, numberOfLines: 3)
    layout.contentStack.setSubtitle(configuration.source)
    layout.contentStack.setDetail(configuration.timestamp)
    layout.accessoryHost.apply(.none, appearance: appearance)
    layout.contentStack.setAccessoryViews([])

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

  public func configure(with viewModel: FKCellArticleRow) {
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
  }
}
