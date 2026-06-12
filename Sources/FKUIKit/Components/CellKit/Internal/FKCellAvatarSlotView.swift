import UIKit

/// Reusable ``FKAvatar`` slot with reuse-safe image cancellation.
@MainActor
final class FKCellAvatarSlotView: UIView {
  private let avatar = FKAvatar()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    configuration: FKAvatarConfiguration,
    displayName: String?,
    imageURL: URL?,
    image: UIImage?
  ) {
    avatar.configuration = configuration
    avatar.displayName = displayName
    avatar.imageURL = imageURL
    avatar.image = image
  }

  func resetForReuse() {
    avatar.resetForReuse()
    avatar.displayName = nil
  }

  private func commonInit() {
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.isUserInteractionEnabled = false
    addSubview(avatar)
    NSLayoutConstraint.activate([
      avatar.topAnchor.constraint(equalTo: topAnchor),
      avatar.leadingAnchor.constraint(equalTo: leadingAnchor),
      avatar.trailingAnchor.constraint(equalTo: trailingAnchor),
      avatar.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
