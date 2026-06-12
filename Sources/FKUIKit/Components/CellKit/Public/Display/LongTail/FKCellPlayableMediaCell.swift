import FKCoreKit
import UIKit
@MainActor
public final class FKCellPlayableMediaCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPlayableMediaRow
  private let layout = FKCellStandardRowLayout(); private let coverView = FKCellImageThumbnailView(); private let playOverlay = UIImageView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellPlayableMediaConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellPlayableMediaConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    coverView.apply(content: configuration.cover)
    playOverlay.isHidden = false
    layout.contentStack.setLeadingContent(coverView, width: FKCellLayoutMetrics.audioCoverSize)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    if configuration.isNowPlaying { layout.contentStack.titleLabel.textColor = .systemBlue }
    layout.contentStack.setAccessoryViews([])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.isEnabled ? .default : .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellPlayableMediaRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); coverView.resetForReuse(); layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear
    playOverlay.image = UIImage(systemName: "play.circle.fill"); playOverlay.tintColor = .white
    playOverlay.translatesAutoresizingMaskIntoConstraints = false; coverView.addSubview(playOverlay)
    NSLayoutConstraint.activate([playOverlay.centerXAnchor.constraint(equalTo: coverView.centerXAnchor), playOverlay.centerYAnchor.constraint(equalTo: coverView.centerYAnchor), playOverlay.widthAnchor.constraint(equalToConstant: 28), playOverlay.heightAnchor.constraint(equalToConstant: 28)])
    layout.install(in: contentView)
  }
}
