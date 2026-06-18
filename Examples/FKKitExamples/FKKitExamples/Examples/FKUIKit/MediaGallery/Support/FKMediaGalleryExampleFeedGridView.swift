import FKUIKit
import UIKit

/// Simulates a social feed thumbnail grid with hero transition sources.
@MainActor
final class FKMediaGalleryExampleFeedGridView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  var onSelect: ((Int, FKImageView) -> Void)?

  private let collectionView: UICollectionView
  private var items: [FKMediaGalleryItem] = []
  private var imageViews: [Int: FKImageView] = [:]

  override init(frame: CGRect) {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 4
    layout.minimumLineSpacing = 4
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(frame: frame)
    collectionView.backgroundColor = .clear
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(FKMediaGalleryExampleThumbCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
      heightAnchor.constraint(equalToConstant: 280),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setItems(_ items: [FKMediaGalleryItem]) {
    self.items = items
    imageViews.removeAll()
    collectionView.reloadData()
  }

  func thumbnailView(at index: Int) -> FKImageView? {
    imageViews[index]
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FKMediaGalleryExampleThumbCell
    cell.configure(item: items[indexPath.item])
    imageViews[indexPath.item] = cell.thumbnailView
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let imageView = imageViews[indexPath.item] else { return }
    onSelect?(indexPath.item, imageView)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let columns: CGFloat = 3
    let spacing: CGFloat = 4
    let width = (collectionView.bounds.width - spacing * (columns - 1)) / columns
    return CGSize(width: floor(width), height: floor(width))
  }
}

@MainActor
private final class FKMediaGalleryExampleThumbCell: UICollectionViewCell {
  let thumbnailView = FKImageView(profile: .listCell)

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.cornerRadius = 6
    contentView.clipsToBounds = true
    thumbnailView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(thumbnailView)
    NSLayoutConstraint.activate([
      thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor),
      thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.resetForReuse()
  }

  func configure(item: FKMediaGalleryItem) {
    switch item.kind {
    case let .image(source):
      switch source {
      case let .url(url, options):
        thumbnailView.cacheKey = options.thumbnailCacheKey ?? options.cacheKey
        thumbnailView.load(url: options.thumbnailURL ?? url)
      case let .image(image):
        thumbnailView.setImage(image, animated: false)
      case let .bundleResource(name, bundle):
        thumbnailView.setImage(UIImage(named: name, in: bundle, compatibleWith: nil), animated: false)
      case .assetLocalIdentifier:
        break
      }
    case .video:
      thumbnailView.apply { config in
        config.loading.placeholder = .symbol(name: "play.rectangle.fill", pointSize: 28, weight: .regular)
      }
      thumbnailView.setImage(nil, animated: false)
    }
  }
}
