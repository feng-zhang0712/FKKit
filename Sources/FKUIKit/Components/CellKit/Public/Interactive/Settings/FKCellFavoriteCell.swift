import FKCoreKit
import UIKit
@MainActor
public final class FKCellFavoriteCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellFavoriteRow
  public var onFavoriteChanged: ((Bool) -> Void)?
  private let layout = FKCellStandardRowLayout(); private let favoriteButton = UIButton(type: .system)
  private var isFavorite = false
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellFavoriteConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellFavoriteConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    isFavorite = configuration.isFavorite; updateFavoriteButton()
    layout.contentStack.setAccessoryViews([favoriteButton])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellFavoriteRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onFavoriteChanged = nil; layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside); layout.install(in: contentView)
  }
  @objc private func favoriteTapped() { isFavorite.toggle(); updateFavoriteButton(); onFavoriteChanged?(isFavorite) }
  private func updateFavoriteButton() {
    let name = isFavorite ? "star.fill" : "star"
    favoriteButton.setImage(UIImage(systemName: name), for: .normal)
    favoriteButton.tintColor = isFavorite ? .systemYellow : .tertiaryLabel
  }
}
