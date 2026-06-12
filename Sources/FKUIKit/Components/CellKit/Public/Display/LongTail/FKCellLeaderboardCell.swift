import FKCoreKit
import UIKit
@MainActor
public final class FKCellLeaderboardCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellLeaderboardRow
  private let layout = FKCellStandardRowLayout()
  private let rankLabel = UILabel(); private let avatarSlot = FKCellAvatarSlotView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellLeaderboardConfiguration) { apply(configuration, appearance: .default, imageURL: nil, image: nil) }
  public func apply(_ configuration: FKCellLeaderboardConfiguration, appearance: FKCellAppearanceConfiguration = .default, imageURL: URL? = nil, image: UIImage? = nil) {
    layout.applyAppearance(appearance)
    rankLabel.text = "\(configuration.rank)"
    rankLabel.textColor = configuration.rank <= 3 ? .systemOrange : .secondaryLabel
    avatarSlot.apply(configuration: configuration.avatarConfiguration, displayName: configuration.name, imageURL: imageURL, image: image)
    let leading = UIStackView(arrangedSubviews: [rankLabel, avatarSlot]); leading.axis = .horizontal; leading.spacing = 8; leading.alignment = .center
  leading.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([rankLabel.widthAnchor.constraint(equalToConstant: 24), avatarSlot.widthAnchor.constraint(equalToConstant: 36), avatarSlot.heightAnchor.constraint(equalToConstant: 36)])
    layout.contentStack.setLeadingContent(leading, width: 72)
    layout.contentStack.setTitle(configuration.name)
    layout.accessoryHost.apply(.value(configuration.scoreText), appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.name
  }
  public func configure(with viewModel: FKCellLeaderboardRow) { apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image) }
  public override func prepareForReuse() { super.prepareForReuse(); avatarSlot.resetForReuse(); layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    rankLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .bold); layout.install(in: contentView)
  }
}
