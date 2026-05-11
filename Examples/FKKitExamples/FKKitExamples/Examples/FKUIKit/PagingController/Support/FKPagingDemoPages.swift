import UIKit

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
