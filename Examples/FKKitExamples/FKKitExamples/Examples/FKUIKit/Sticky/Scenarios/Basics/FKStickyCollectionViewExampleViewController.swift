import FKUIKit
import UIKit

/// Sticky strip as a `UICollectionView` content subview (installed after the first layout).
final class FKStickyCollectionViewExampleViewController: UIViewController, UICollectionViewDataSource {
  private var collectionView: UICollectionView!
  private let statusLabel = FKStickyExampleUI.statusLabel()
  private let strip = FKStickyExampleStripView(title: "Collection filters", backgroundColor: .systemTeal)
  private let items = (0..<48).map { "Item \($0 + 1)" }
  private let stripHeight: CGFloat = 48
  private let stripTop: CGFloat = 12
  private var didInstallStrip = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UICollectionView"
    view.backgroundColor = .systemBackground

    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    layout.sectionInset = UIEdgeInsets(top: stripTop + stripHeight + 12, left: 16, bottom: 24, right: 16)

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.dataSource = self
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)
    NSLayoutConstraint.activate([
      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    strip.translatesAutoresizingMaskIntoConstraints = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = collectionView.bounds.width - 32
    guard width > 1 else { return }

    if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
      let side = (
        collectionView.bounds.width
          - layout.sectionInset.left
          - layout.sectionInset.right
          - layout.minimumInteritemSpacing
      ) / 2
      layout.itemSize = CGSize(width: floor(side), height: 88)
    }

    if !didInstallStrip {
      didInstallStrip = true
      // Install only after we have a real width — avoids `width == 0` autoresizing conflicts.
      strip.frame = CGRect(x: 16, y: stripTop, width: width, height: stripHeight)
      collectionView.addSubview(strip)
      collectionView.fk_addStickyTarget(id: "collection-filters", view: strip) { [weak self] progress in
        self?.statusLabel.text =
          "collection-filters → \(progress.state.rawValue) p=\(String(format: "%.2f", progress.value))"
      }
      collectionView.fk_reloadStickyLayout()
      return
    }

    // Keep the idle frame in sync with rotation / size changes; skip while stuck in the overlay.
    if strip.superview === collectionView {
      strip.frame = CGRect(x: 16, y: stripTop, width: width, height: stripHeight)
      collectionView.fk_reloadStickyLayout()
    }
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.contentView.backgroundColor = .secondarySystemBackground
    cell.contentView.layer.cornerRadius = 10
    let tag = 42
    let label: UILabel
    if let existing = cell.contentView.viewWithTag(tag) as? UILabel {
      label = existing
    } else {
      label = UILabel()
      label.tag = tag
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = .preferredFont(forTextStyle: .subheadline)
      cell.contentView.addSubview(label)
      NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    }
    label.text = items[indexPath.item]
    return cell
  }
}
