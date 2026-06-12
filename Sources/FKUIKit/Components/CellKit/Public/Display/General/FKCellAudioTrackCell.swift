import FKCoreKit
import UIKit

/// Audio or podcast track row with cover art and duration (D-24).
@MainActor
public final class FKCellAudioTrackCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellAudioTrackRow

  private let layout = FKCellStandardRowLayout()
  private let coverView = FKCellImageThumbnailView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellAudioTrackConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellAudioTrackConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    coverView.apply(content: configuration.cover)
    layout.contentStack.setLeadingContent(coverView, width: FKCellLayoutMetrics.audioCoverSize)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.artist)
    layout.contentStack.setDetail(configuration.duration)
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

  public func configure(with viewModel: FKCellAudioTrackRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    coverView.resetForReuse()
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
