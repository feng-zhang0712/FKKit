import FKCoreKit
import UIKit

/// Placeholder collection cell with feed-style skeleton blocks for ``FKListSkeletonPolicy/presetRows(count:)``.
@MainActor
public final class FKListSkeletonPlaceholderCollectionCell: UICollectionViewCell, FKListCollectionCellConfigurable {
  public typealias Item = FKListSkeletonPlaceholder.Context

  public static let reuseIdentifier = FKListSkeletonPlaceholder.collectionCellTypeIdentifier

  private let skeletonHost = FKSkeletonContainerView()
  private var didApplyLayout = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  public func configure(with item: FKListSkeletonPlaceholder.Context) {
    applySkeletonLayoutIfNeeded()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    skeletonHost.removeAllSkeletonSubviews()
    didApplyLayout = false
  }

  private func setup() {
    isUserInteractionEnabled = false
    backgroundColor = .systemBackground
    contentView.backgroundColor = .systemBackground
    skeletonHost.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(skeletonHost)
    NSLayoutConstraint.activate([
      skeletonHost.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      skeletonHost.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      skeletonHost.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      skeletonHost.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  private func applySkeletonLayoutIfNeeded() {
    guard !didApplyLayout else { return }
    didApplyLayout = true
    skeletonHost.removeAllSkeletonSubviews()

    let avatar = FKSkeletonView()
    avatar.layer.cornerRadius = 22
    let titleLine = FKSkeletonView()
    titleLine.layer.cornerRadius = 4
    let subtitleLine = FKSkeletonView()
    subtitleLine.layer.cornerRadius = 4
    [avatar, titleLine, subtitleLine].forEach { skeletonHost.addSkeletonSubview($0) }

    let avatarSize: CGFloat = 44
    let spacing: CGFloat = 12
    let titleWidthRatio: CGFloat = 0.55
    let subtitleWidthRatio: CGFloat = 0.35
    let widthInset = titleWidthRatio * (avatarSize + spacing)
    let subtitleWidthInset = subtitleWidthRatio * (avatarSize + spacing)

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: skeletonHost.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: skeletonHost.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: avatarSize),
      avatar.heightAnchor.constraint(equalToConstant: avatarSize),

      titleLine.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: spacing),
      titleLine.heightAnchor.constraint(equalToConstant: 14),
      titleLine.bottomAnchor.constraint(equalTo: skeletonHost.centerYAnchor, constant: -4),
      titleLine.widthAnchor.constraint(
        equalTo: skeletonHost.widthAnchor,
        multiplier: titleWidthRatio,
        constant: -widthInset
      ),

      subtitleLine.leadingAnchor.constraint(equalTo: titleLine.leadingAnchor),
      subtitleLine.heightAnchor.constraint(equalToConstant: 12),
      subtitleLine.topAnchor.constraint(equalTo: skeletonHost.centerYAnchor, constant: 4),
      subtitleLine.widthAnchor.constraint(
        equalTo: skeletonHost.widthAnchor,
        multiplier: subtitleWidthRatio,
        constant: -subtitleWidthInset
      ),
    ])
  }
}
