import UIKit
import FKUIKit

/// Shared demo pages and layout helpers for paging examples.
@MainActor
enum FKPagingDemoSupport {
  /// Embeds a child view controller edge-to-edge in the host.
  static func embedFullScreen(_ child: UIViewController, in host: UIViewController) {
    host.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    child.view.clipsToBounds = true
    host.view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: host.view.topAnchor),
      child.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
    ])
    child.didMove(toParent: host)
  }

  /// Embeds ``FKPagingController`` below an externally managed ``FKTabBar`` (``.external`` placement).
  static func embedPagingController(
    _ pagingController: FKPagingController,
    below tabBar: FKTabBar,
    in host: UIViewController,
    tabBarHeight: CGFloat? = nil
  ) {
    host.addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    pagingController.view.clipsToBounds = true
    host.view.addSubview(pagingController.view)

    tabBar.translatesAutoresizingMaskIntoConstraints = false
    if tabBar.superview !== host.view {
      host.view.addSubview(tabBar)
    }

    let height = tabBarHeight ?? max(44, tabBar.intrinsicContentSize.height)
    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: height),
      pagingController.view.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
      pagingController.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
    ])
    pagingController.didMove(toParent: host)
  }
}

/// Solid-color demo page used across paging examples.
@MainActor
final class FKPagingDemoPageViewController: UIViewController {
  private let color: UIColor
  private let titleText: String

  init(color: UIColor, titleText: String) {
    self.color = color
    self.titleText = titleText
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = color
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = titleText
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.textColor = .white
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

/// Nested scroll content to validate paging vs vertical scroll gesture arbitration.
@MainActor
final class FKPagingDemoListViewController: UITableViewController {
  private let rows = (0..<80).map { "Row item \($0)" }
  private let headerTitle: String

  init(headerTitle: String) {
    self.headerTitle = headerTitle
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.backgroundColor = .secondarySystemBackground
    let header = UILabel()
    header.font = .preferredFont(forTextStyle: .headline)
    header.textColor = .label
    header.text = headerTitle
    header.textAlignment = .center
    header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52)
    tableView.tableHeaderView = header
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = rows[indexPath.row]
    return cell
  }
}

/// Horizontally scrollable content to exercise nested scroll vs pager pan arbitration.
@MainActor
final class FKPagingDemoHorizontalCarouselViewController: UIViewController, UICollectionViewDelegate {
  private let headerTitle: String
  private let collectionView: UICollectionView

  init(headerTitle: String) {
    self.headerTitle = headerTitle
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = CGSize(width: 220, height: 160)
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .secondarySystemBackground
    let header = UILabel()
    header.translatesAutoresizingMaskIntoConstraints = false
    header.font = .preferredFont(forTextStyle: .headline)
    header.textAlignment = .center
    header.text = headerTitle
    view.addSubview(header)

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = true
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension FKPagingDemoHorizontalCarouselViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 12 }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15 + CGFloat(indexPath.item) * 0.05)
    cell.contentView.layer.cornerRadius = 12
    cell.contentView.layer.masksToBounds = true
    return cell
  }
}

extension FKPagingDemoSupport {
  /// Monospaced log panel used by delegate-heavy paging scenarios.
  static func makeLogTextView() -> UITextView {
    let logView = UITextView()
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    return logView
  }

  static func appendLog(_ line: String, to logView: UITextView) {
    logView.text = (logView.text ?? "") + line + "\n"
    let bottom = NSRange(location: max(0, logView.text.count - 1), length: 1)
    logView.scrollRangeToVisible(bottom)
  }
}
