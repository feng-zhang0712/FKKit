import FKCoreKit
import UIKit

/// Collection variant of ``FKCellConversationCell`` sharing the same content view (D-20).
@MainActor
public final class FKCellConversationCollectionCell: UICollectionViewCell, FKCellCollectionReusable {
  public typealias ViewModel = FKCellConversationRow

  private let conversationContent = FKCellConversationContentView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
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
    conversationContent.apply(
      configuration: configuration,
      appearance: appearance,
      imageURL: imageURL,
      image: image,
      host: self
    )
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellConversationRow) {
    apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    conversationContent.resetForReuse()
    accessibilityLabel = nil
    contentView.backgroundColor = FKCellAppearanceConfiguration.default.cellBackgroundColor
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
