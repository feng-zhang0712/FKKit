import FKCoreKit
import UIKit

/// Message inbox conversation preview row (D-20).
@MainActor
public final class FKCellConversationCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellConversationRow

  private let conversationContent = FKCellConversationContentView()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellConversationConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil)
  }

  public func apply(
    _ configuration: FKCellConversationConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil
  ) {
    self.appearance = appearance
    conversationContent.apply(
      configuration: configuration,
      appearance: appearance,
      imageURL: imageURL,
      image: image,
      host: self
    )
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellConversationRow) {
    apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    conversationContent.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
    contentView.backgroundColor = appearance.cellBackgroundColor
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    conversationContent.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(conversationContent)
    NSLayoutConstraint.activate([
      conversationContent.topAnchor.constraint(equalTo: contentView.topAnchor),
      conversationContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      conversationContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      conversationContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
