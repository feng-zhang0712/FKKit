import FKCompositeKit
import UIKit

/// Demonstrates ``FKBaseCollectionViewController`` with a two-column flow, pull-to-refresh, and load-more.
final class FKBaseCollectionViewControllerExampleViewController: FKBaseCollectionViewController {

  private static let reuseId = "cell"
  private var items: [UIColor] = []
  private var loadMorePages = 0

  override init() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    super.init(collectionViewLayout: layout)
    isPullToRefreshEnabled = true
    isLoadMoreEnabled = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBaseCollectionViewController"
  }

  override func configureCollectionView(_ collectionView: UICollectionView) {
    super.configureCollectionView(collectionView)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.reuseId)
  }

  override func loadInitialContent() {
    super.loadInitialContent()
    items = [
      .systemBlue, .systemGreen, .systemOrange, .systemPurple,
      .systemTeal, .systemIndigo, .systemPink, .systemYellow,
    ]
    collectionView.reloadData()
  }

  override func performPullToRefresh() {
    loadMorePages = 0
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
      guard let self else { return }
      self.items = [.systemRed, .systemCyan, .systemMint, .systemBrown]
      self.collectionView.reloadData()
      self.endPullToRefresh(success: true)
    }
  }

  override func performLoadMore() {
    loadMorePages += 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self else { return }
      if self.loadMorePages >= 2 {
        self.markLoadMoreNoMoreData()
        return
      }
      let extras: [UIColor] = [.darkGray, .lightGray, .label, .secondaryLabel]
      self.items.append(contentsOf: extras)
      self.collectionView.reloadData()
      self.markLoadMoreFinished()
    }
  }
}

extension FKBaseCollectionViewControllerExampleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.reuseId, for: indexPath)
    cell.contentView.backgroundColor = items[indexPath.item]
    cell.contentView.layer.cornerRadius = 8
    cell.contentView.clipsToBounds = true
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let layout = collectionViewLayout as! UICollectionViewFlowLayout
    let inset = layout.sectionInset.left + layout.sectionInset.right
    let spacing = layout.minimumInteritemSpacing
    let width = (collectionView.bounds.width - inset - spacing) / 2
    return CGSize(width: max(60, width), height: 72)
  }
}

extension FKBaseCollectionViewControllerExampleViewController: UICollectionViewDataSourcePrefetching {
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {}
}
