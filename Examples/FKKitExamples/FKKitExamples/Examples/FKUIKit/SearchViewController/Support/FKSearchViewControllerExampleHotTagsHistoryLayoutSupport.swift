import FKUIKit
import UIKit

/// Fixtures and helpers for the hot-tags + history layout demo (Examples only).
enum FKSearchViewControllerExampleHotTagsHistoryLayoutSupport {

  static let hotSearchTerms: [String] = [
    "Java", "Python", "Objective-C", "Swift", "C", "C++", "PHP", "C#",
    "Perl", "Go", "JavaScript", "R", "Ruby", "MATLAB",
  ]

  static let extendedCatalog: [String] = hotSearchTerms + [
    "Kotlin", "Rust", "Dart", "Scala", "Lua", "Haskell", "TypeScript", "Elixir",
  ]

  private static let systemsLanguages: Set<String> = [
    "C", "C++", "Objective-C", "Swift", "Go", "Rust", "Kotlin", "Java", "C#",
  ]

  private static let scriptingLanguages: Set<String> = [
    "Python", "JavaScript", "Ruby", "Perl", "PHP", "Lua", "R", "MATLAB", "TypeScript", "Elixir",
  ]

  static func filteredLanguages(for query: String) -> [String] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    return extendedCatalog.filter { $0.localizedCaseInsensitiveContains(trimmed) }
  }

  static func partition(_ languageNames: [String]) -> (all: [String], systems: [String], scripting: [String]) {
    let systems = languageNames.filter { systemsLanguages.contains($0) }
    let scripting = languageNames.filter { scriptingLanguages.contains($0) }
    return (languageNames, systems, scripting)
  }

  private static func categoryLabel(for name: String) -> String {
    if systemsLanguages.contains(name) { return "Systems language" }
    if scriptingLanguages.contains(name) { return "Scripting language" }
    return "Programming language"
  }

  static func subtitle(for languageName: String) -> String {
    categoryLabel(for: languageName)
  }
}

/// In-memory recent-search store for the hot-tags idle page.
@MainActor
final class FKSearchViewControllerExampleSearchHistoryStore {
  private(set) var items: [String]

  var onChange: (() -> Void)?

  init(seed: [String] = ["R", "Swift", "Objective-C", "Ruby"]) {
    self.items = seed
  }

  func record(_ term: String) {
    let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    items.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    items.insert(trimmed, at: 0)
    if items.count > 12 {
      items = Array(items.prefix(12))
    }
    onChange?()
  }

  func remove(at index: Int) {
    guard items.indices.contains(index) else { return }
    items.remove(at: index)
    onChange?()
  }

  func removeAll() {
    guard !items.isEmpty else { return }
    items.removeAll()
    onChange?()
  }
}

/// Idle page: hot tag cloud + searchable history list.
@MainActor
final class FKSearchViewControllerExampleHotTagsIdleViewController: UITableViewController {
  var onSelectTerm: ((String) -> Void)?
  var onDeleteHistory: ((Int) -> Void)?
  var onClearHistory: (() -> Void)?

  private let historyStore: FKSearchViewControllerExampleSearchHistoryStore
  private let hotTerms: [String]
  private var hotSearchHeaderView: UIView?
  private var chipGroup: FKChipGroup?
  private var lastHotHeaderSize = CGSize.zero

  init(
    historyStore: FKSearchViewControllerExampleSearchHistoryStore,
    hotTerms: [String] = FKSearchViewControllerExampleHotTagsHistoryLayoutSupport.hotSearchTerms
  ) {
    self.historyStore = historyStore
    self.hotTerms = hotTerms
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 16)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "history")
    installHotSearchHeader()
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 24))

    historyStore.onChange = { [weak self] in
      self?.tableView.reloadData()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    resizeHotSearchHeaderIfNeeded()
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    max(historyStore.items.count, 1)
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let container = UIView()
    container.backgroundColor = .systemBackground

    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = "Search History"
    title.font = .preferredFont(forTextStyle: .footnote)
    title.textColor = .secondaryLabel

    let clearButton = UIButton(type: .system)
    clearButton.translatesAutoresizingMaskIntoConstraints = false
    clearButton.setTitle("Clear", for: .normal)
    clearButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
    clearButton.isHidden = historyStore.items.isEmpty
    clearButton.addAction(UIAction { [weak self] _ in
      self?.onClearHistory?()
    }, for: .touchUpInside)

    container.addSubview(title)
    container.addSubview(clearButton)
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      title.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      clearButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      clearButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      container.heightAnchor.constraint(equalToConstant: 36),
    ])
    return container
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 36 }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "history", for: indexPath)
    var config = cell.defaultContentConfiguration()

    if historyStore.items.isEmpty {
      config.text = "No recent searches"
      config.textProperties.color = .tertiaryLabel
      config.textProperties.font = .preferredFont(forTextStyle: .subheadline)
      config.image = nil
      cell.accessoryView = nil
      cell.selectionStyle = .none
    } else {
      let term = historyStore.items[indexPath.row]
      config.text = term
      config.textProperties.color = .label
      config.image = UIImage(systemName: "clock.arrow.circlepath")
      config.imageProperties.tintColor = .secondaryLabel
      cell.selectionStyle = .default

      let deleteButton = UIButton(type: .system)
      deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
      deleteButton.tintColor = .tertiaryLabel
      deleteButton.tag = indexPath.row
      deleteButton.addAction(UIAction { [weak self] action in
        guard let button = action.sender as? UIButton else { return }
        self?.onDeleteHistory?(button.tag)
      }, for: .touchUpInside)
      cell.accessoryView = deleteButton
    }

    cell.contentConfiguration = config
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard historyStore.items.indices.contains(indexPath.row) else { return }
    onSelectTerm?(historyStore.items[indexPath.row])
  }

  private func installHotSearchHeader() {
    let width = resolvedTableWidth()
    let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 44))
    header.backgroundColor = .systemBackground

    let title = UILabel()
    title.text = "Hot Searches"
    title.font = .preferredFont(forTextStyle: .footnote)
    title.textColor = .secondaryLabel

    var groupConfig = FKChipGroupConfiguration()
    groupConfig.chipMode = .suggestion
    groupConfig.layoutMode = .flow(wrap: true)

    let chips = hotTerms.map { FKChipItem(id: $0.lowercased(), title: $0) }
    let group = FKChipGroup(configuration: groupConfig, chips: chips, selectionMode: .none)
    group.onChipPrimaryAction = { [weak self] id in
      guard let self else { return }
      let term = self.hotTerms.first { $0.lowercased() == id } ?? id
      self.onSelectTerm?(term)
    }

    header.addSubview(title)
    header.addSubview(group)
    hotSearchHeaderView = header
    chipGroup = group
    layoutHotSearchHeader(header, width: width)
    lastHotHeaderSize = header.frame.size
    tableView.tableHeaderView = header
  }

  private func resizeHotSearchHeaderIfNeeded() {
    guard let header = hotSearchHeaderView else { return }
    let width = resolvedTableWidth()
    guard width > 0 else { return }
    layoutHotSearchHeader(header, width: width)
    let size = header.frame.size
    guard abs(size.width - lastHotHeaderSize.width) > 0.5
      || abs(size.height - lastHotHeaderSize.height) > 0.5 else { return }
    lastHotHeaderSize = size
    tableView.tableHeaderView = header
  }

  private func layoutHotSearchHeader(_ header: UIView, width: CGFloat) {
    let horizontalInset: CGFloat = 16
    let contentWidth = max(width - horizontalInset * 2, 1)

    let title = header.subviews.compactMap { $0 as? UILabel }.first
    let group = chipGroup

    title?.frame = CGRect(x: horizontalInset, y: 12, width: contentWidth, height: 18)

    guard let group else {
      header.frame.size = CGSize(width: width, height: 44)
      return
    }

    let chipTop = (title?.frame.maxY ?? 12) + 10
    let chipSize = group.sizeThatFits(CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height))
    let chipHeight = max(chipSize.height, 1)
    group.frame = CGRect(x: horizontalInset, y: chipTop, width: contentWidth, height: chipHeight)

    let height = ceil(group.frame.maxY + 12)
    header.frame.size = CGSize(width: width, height: height)
  }

  private func resolvedTableWidth() -> CGFloat {
    if tableView.bounds.width > 0 { return tableView.bounds.width }
    if let width = view.window?.bounds.width, width > 0 { return width }
    return UIScreen.main.bounds.width
  }
}

/// Single tab page listing programming-language matches.
@MainActor
final class FKSearchViewControllerExampleHotTagsResultsListPageViewController: UITableViewController {
  var languageNames: [String] = [] {
    didSet { tableView.reloadData() }
  }

  private let pageTitle: String

  init(pageTitle: String) {
    self.pageTitle = pageTitle
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "result")
    tableView.backgroundColor = .systemBackground
    tableView.tableHeaderView = makeHeader()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    languageNames.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "result", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = languageNames[indexPath.row]
    config.secondaryText = FKSearchViewControllerExampleHotTagsHistoryLayoutSupport.subtitle(for: languageNames[indexPath.row])
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  private func makeHeader() -> UIView {
    headerLabel
  }

  private lazy var headerLabel: UILabel = {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.text = pageTitle
    return label
  }()

  func updateHeader(_ text: String) {
    headerLabel.text = text
    headerLabel.frame.size.height = 44
    tableView.tableHeaderView = headerLabel
  }
}

/// Tabbed results page pushed after a query (``FKPagingTabBarPlacement/contentTop``).
@MainActor
final class FKSearchViewControllerExampleHostPushedTabbedResultsViewController: UIViewController {
  let query: String

  private let pagingController: FKPagingController
  private let allPage = FKSearchViewControllerExampleHotTagsResultsListPageViewController(pageTitle: "All matches")
  private let systemsPage = FKSearchViewControllerExampleHotTagsResultsListPageViewController(pageTitle: "Systems languages")
  private let scriptingPage = FKSearchViewControllerExampleHotTagsResultsListPageViewController(pageTitle: "Scripting languages")
  private let emptyLabel = UILabel()

  init(query: String) {
    self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)

    var config = FKPagingConfiguration()
    config.tabBarPlacement = .contentTop
    config.tabBarHeightPolicy = .fixed(48)

    let tabs = FKTabBarExampleSupport.makeTitleOnlyItems(
      3,
      localizedTitles: ["All", "Systems", "Scripting"]
    )
    let pages: [UIViewController] = [allPage, systemsPage, scriptingPage]

    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      tabConfiguration: FKTabBarPresets.pagerHeader(),
      configuration: config
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = query.isEmpty ? "Results" : query

    emptyLabel.translatesAutoresizingMaskIntoConstraints = false
    emptyLabel.font = .preferredFont(forTextStyle: .body)
    emptyLabel.textColor = .secondaryLabel
    emptyLabel.textAlignment = .center
    emptyLabel.numberOfLines = 0
    emptyLabel.isHidden = true
    view.addSubview(emptyLabel)

    NSLayoutConstraint.activate([
      emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
      emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
    ])

    applyResults()
  }

  private func applyResults() {
    let names = FKSearchViewControllerExampleHotTagsHistoryLayoutSupport.filteredLanguages(for: query)
    guard !names.isEmpty else {
      pagingController.view.isHidden = true
      emptyLabel.isHidden = false
      emptyLabel.text = "No results for \"\(query)\""
      return
    }

    let buckets = FKSearchViewControllerExampleHotTagsHistoryLayoutSupport.partition(names)
    allPage.languageNames = buckets.all
    systemsPage.languageNames = buckets.systems
    scriptingPage.languageNames = buckets.scripting
    allPage.updateHeader("All matches for \"\(query)\"")
    systemsPage.updateHeader("\(buckets.systems.count) systems match(es)")
    scriptingPage.updateHeader("\(buckets.scripting.count) scripting match(es)")

    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)
    pagingController.view.isHidden = false
    emptyLabel.isHidden = true
  }
}
