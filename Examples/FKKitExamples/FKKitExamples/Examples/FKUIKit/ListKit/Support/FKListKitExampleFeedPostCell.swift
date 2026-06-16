import FKCoreKit
import FKUIKit
import UIKit

/// Custom feed row used by the complex feed reference scenario.
final class FKListKitExampleFeedPostCell: UITableViewCell, FKListTableCellConfigurable {
  typealias Item = FKListKitExampleFeedPost
  var onLikeTapped: ((FKListItemID) -> Void)?

  private let avatarView = FKImageView(profile: .listCell)
  private let authorLabel = UILabel()
  private let bodyLabel = UILabel()
  private let mediaView = FKImageView()
  private let likeButton = UIButton(type: .system)
  private var itemID: FKListItemID?
  private var mediaHeightConstraint: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  func configure(with post: FKListKitExampleFeedPost) {
    itemID = post.id
    authorLabel.text = post.authorName
    bodyLabel.text = post.body
    likeButton.setTitle("♥ \(post.likeCount)", for: .normal)

    avatarView.resetForReuse()
    avatarView.url = FKListKitExampleIcons.remoteURL(id: post.avatarPhotoID)

    if let mediaID = post.mediaPhotoID {
      mediaView.isHidden = false
      mediaHeightConstraint?.isActive = true
      mediaView.resetForReuse()
      mediaView.url = URL(string: "https://picsum.photos/id/\(mediaID)/640/360")!
    } else {
      mediaView.resetForReuse()
      mediaView.isHidden = true
      mediaHeightConstraint?.isActive = false
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    itemID = nil
    avatarView.resetForReuse()
    mediaView.resetForReuse()
    mediaView.isHidden = true
    mediaHeightConstraint?.isActive = false
    onLikeTapped = nil
  }

  private func setup() {
    selectionStyle = .none
    authorLabel.font = .preferredFont(forTextStyle: .headline)
    bodyLabel.font = .preferredFont(forTextStyle: .body)
    bodyLabel.numberOfLines = 0
    bodyLabel.textColor = .label

    mediaView.isHidden = true
    mediaView.contentMode = .scaleAspectFill
    mediaView.clipsToBounds = true
    mediaView.layer.cornerRadius = 8

    likeButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
    likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

    let headerStack = UIStackView(arrangedSubviews: [avatarView, authorLabel])
    headerStack.axis = .horizontal
    headerStack.spacing = 12
    headerStack.alignment = .top

    let rootStack = UIStackView(arrangedSubviews: [headerStack, bodyLabel, mediaView, likeButton])
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.alignment = .fill
    rootStack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(rootStack)

    avatarView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    let mediaHeight = mediaView.heightAnchor.constraint(equalToConstant: 180)
    mediaHeight.priority = .defaultHigh
    mediaHeight.isActive = false
    mediaHeightConstraint = mediaHeight
    let bottom = rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
    bottom.priority = .defaultHigh
    NSLayoutConstraint.activate([
      avatarView.widthAnchor.constraint(equalToConstant: 40),
      avatarView.heightAnchor.constraint(equalToConstant: 40),
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      bottom,
    ])
  }

  @objc private func likeTapped() {
    guard let itemID else { return }
    onLikeTapped?(itemID)
  }
}
