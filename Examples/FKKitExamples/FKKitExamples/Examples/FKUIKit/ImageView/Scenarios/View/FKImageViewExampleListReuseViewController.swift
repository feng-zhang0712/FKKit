import FKCoreKit
import FKUIKit
import UIKit

final class FKImageViewExampleListReuseViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var photoIDs = FKImageViewExampleURLs.feedIDs(count: 200)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "List reuse"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FKImageViewExampleFeedCell.self, forCellReuseIdentifier: FKImageViewExampleFeedCell.reuseID)
    tableView.dataSource = self
    tableView.rowHeight = 88
    tableView.prefetchDataSource = self
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension FKImageViewExampleListReuseViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    photoIDs.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FKImageViewExampleFeedCell.reuseID, for: indexPath) as! FKImageViewExampleFeedCell
    let id = photoIDs[indexPath.row]
    cell.configure(id: id, title: "Photo #\(id)")
    return cell
  }
}

extension FKImageViewExampleListReuseViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = indexPaths.map { FKImageViewExampleURLs.photo(id: photoIDs[$0.row], size: 120) }
    Task {
      await FKImageLoader.shared.prefetch(urls: urls, targetSize: CGSize(width: 120, height: 120))
    }
  }

  func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      let request = FKImageLoadRequest(
        url: FKImageViewExampleURLs.photo(id: photoIDs[indexPath.row], size: 120),
        targetSize: CGSize(width: 120, height: 120)
      )
      FKImageLoader.shared.cancelPrefetch(for: request)
    }
  }
}

@MainActor
private final class FKImageViewExampleFeedCell: UITableViewCell {
  static let reuseID = "FKImageViewExampleFeedCell"

  private let thumb = FKImageView(profile: .listCell)
  private let titleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    titleLabel.font = .preferredFont(forTextStyle: .body)

    thumb.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(thumb)
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      thumb.widthAnchor.constraint(equalToConstant: 64),
      thumb.heightAnchor.constraint(equalToConstant: 64),
      titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumb.resetForReuse()
  }

  func configure(id: Int, title: String) {
    titleLabel.text = title
    thumb.load(url: FKImageViewExampleURLs.photo(id: id, size: 120))
  }
}
