import FKCoreKit
import UIKit
@MainActor
public final class FKCellNowPlayingCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellNowPlayingRow
  public var onPlayPauseTap: (() -> Void)?
  private let layout = FKCellStandardRowLayout(); private let coverView = FKCellImageThumbnailView(); private let playButton = UIButton(type: .system)
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellNowPlayingConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellNowPlayingConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    coverView.apply(content: configuration.cover)
    layout.contentStack.setLeadingContent(coverView, width: FKCellLayoutMetrics.audioCoverSize)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.artist)
    let symbol = configuration.isPlaying ? "pause.circle.fill" : "play.circle.fill"
    playButton.setImage(UIImage(systemName: symbol), for: .normal)
    layout.contentStack.setAccessoryViews([playButton])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellNowPlayingRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onPlayPauseTap = nil; coverView.resetForReuse(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    playButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside); layout.install(in: contentView)
  }
  @objc private func playPauseTapped() { onPlayPauseTap?() }
}
