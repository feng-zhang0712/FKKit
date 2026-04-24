import UIKit
import FKUIKit

final class FKPagingControllerBasicExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var stressWorkItem: DispatchWorkItem?

  init() {
    var tabs = FKTabBarExampleSupport.makeItems(5)
    tabs[2].badge.state.normal = .count(6)
    let tabAppearance = FKTabBarAppearance(
      indicatorStyle: .line(
        FKTabBarLineIndicatorConfiguration(
          position: .bottom,
          thickness: 3,
          fill: .solid(.systemBlue),
          leadingInset: 10,
          trailingInset: 10,
          cornerRadius: 1.5,
          followMode: .trackContentProgress
        )
      )
    )
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Home feed"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Explore"),
      FKPagingDemoListViewController(titleText: "Inbox"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Profile"),
      FKPagingDemoPageViewController(color: .systemPurple, titleText: "Settings"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 0,
      tabAppearance: tabAppearance,
      configuration: FKPagingConfiguration(
        tabBarHeight: 52,
        allowsSwipePaging: true,
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1),
        gesturePolicy: .preferNavigationBackGesture(edgeWidth: 28)
      )
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Paging + TabBar"
    view.backgroundColor = .systemBackground
    embed(pagingController)
    installVerificationActions()
    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .footnote)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "FollowMode is set to trackContentProgress in this demo. Swipe pages and observe smooth indicator interpolation."
    note.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(note)
    NSLayoutConstraint.activate([
      note.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      note.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      note.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -62),
    ])
  }

  private func embed(_ child: UIViewController) {
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: view.topAnchor),
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    child.didMove(toParent: self)
  }

  private func installVerificationActions() {
    let panel = UIStackView()
    panel.axis = .horizontal
    panel.spacing = 8
    panel.distribution = .fillEqually
    panel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(panel)

    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Prev") { [weak self] in
      guard let self else { return }
      pagingController.setSelectedIndex(max(0, pagingController.selectedIndex - 1), animated: true)
    })
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Next") { [weak self] in
      guard let self else { return }
      pagingController.setSelectedIndex(min(pagingController.pageCount - 1, pagingController.selectedIndex + 1), animated: true)
    })
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Stress x20") { [weak self] in
      guard let self else { return }
      self.stressWorkItem?.cancel()
      let work = DispatchWorkItem { [weak self] in
        guard let self else { return }
        for step in 0..<20 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(step)) { [weak self] in
            guard let self else { return }
            let target = (step * 3) % max(1, self.pagingController.pageCount)
            self.pagingController.setSelectedIndex(target, animated: true)
          }
        }
      }
      self.stressWorkItem = work
      DispatchQueue.main.async(execute: work)
    })

    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      panel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}

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
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = color
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = titleText
    label.font = .systemFont(ofSize: 30, weight: .bold)
    label.textColor = .white
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

@MainActor
final class FKPagingDemoListViewController: UITableViewController {
  private let rows = (0..<80).map { "Message \($0)" }
  private let titleText: String

  init(titleText: String) {
    self.titleText = titleText
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.backgroundColor = .systemBackground
    let header = UILabel()
    header.font = .preferredFont(forTextStyle: .headline)
    header.textColor = .label
    header.text = titleText
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
