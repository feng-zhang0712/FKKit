import FKUIKit
import UIKit

/// Banner embedded in UITableView tableHeaderView with vertical scrolling.
final class FKCarouselTableHeaderExampleViewController: UIViewController, UITableViewDataSource {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private let banner = FKImageBanner(configuration: FKImageBannerPresets.homeHero())
  private lazy var headerContainer: UIView = {
    let header = UIView()
    header.backgroundColor = .clear
    banner.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(banner)
    NSLayoutConstraint.activate([
      banner.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
      banner.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
      banner.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
      banner.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),
    ])
    return header
  }()

  private var didInstallTableHeader = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table header"
    view.backgroundColor = .systemGroupedBackground

    banner.setSlides(FKCarouselExampleSlides.heroSlides(count: 4))

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard tableView.bounds.width > 0 else { return }

    if !didInstallTableHeader {
      tableView.tableHeaderView = headerContainer
      didInstallTableHeader = true
    }
    resizeTableHeaderIfNeeded()
  }

  /// Sizes the header once `tableView` has a non-zero width (avoids zero-width Auto Layout warnings).
  private func resizeTableHeaderIfNeeded() {
    guard let header = tableView.tableHeaderView else { return }
    let width = tableView.bounds.width
    guard width > 0 else { return }

    header.frame.size.width = width
    let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
    let height = header.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height

    guard abs(header.frame.height - height) > 0.5 else { return }
    header.frame.size.height = height
    tableView.tableHeaderView = header
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 24 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = "Feed row \(indexPath.row + 1)"
    content.secondaryText = "Scroll vertically — banner auto-scroll pauses when off-screen."
    cell.contentConfiguration = content
    return cell
  }
}
