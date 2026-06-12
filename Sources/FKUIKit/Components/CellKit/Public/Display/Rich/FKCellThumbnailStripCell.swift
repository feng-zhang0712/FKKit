import FKCoreKit
import UIKit

/// Horizontal scrolling thumbnail strip row (D-26).
@MainActor
public final class FKCellThumbnailStripCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellThumbnailStripRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.showsHorizontalScrollIndicator = false
    view.dataSource = self
    view.delegate = self
    view.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.reuseIdentifier)
    return view
  }()

  private let separator = FKCellSeparatorLayout.makeDivider()
  private var thumbnails: [FKCellImageContent] = []
  private var itemSize: CGFloat = 72

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellThumbnailStripConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellThumbnailStripConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    thumbnails = configuration.thumbnails
    itemSize = configuration.itemSize
    collectionView.reloadData()

    groupedBackgroundHost.apply(nil, in: contentView)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    selectionStyle = .none
    accessibilityLabel = "Thumbnail strip, \(configuration.thumbnails.count) items"
  }

  public func configure(with viewModel: FKCellThumbnailStripRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    thumbnails = []
    collectionView.reloadData()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(collectionView)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      collectionView.heightAnchor.constraint(equalToConstant: 88),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}

extension FKCellThumbnailStripCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    thumbnails.count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ThumbnailCell.reuseIdentifier,
      for: indexPath
    ) as! ThumbnailCell
    cell.apply(content: thumbnails[indexPath.item])
    return cell
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    CGSize(width: itemSize, height: itemSize)
  }
}

@MainActor
private final class ThumbnailCell: UICollectionViewCell {
  static let reuseIdentifier = "FKCellThumbnailStripItem"

  private let thumbnailView = FKCellImageThumbnailView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    thumbnailView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(thumbnailView)
    NSLayoutConstraint.activate([
      thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor),
      thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(content: FKCellImageContent) {
    thumbnailView.apply(content: content)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.resetForReuse()
  }
}
