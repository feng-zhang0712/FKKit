import FKUIKit
import UIKit

/// Shared fixtures and mock providers for ``FKSearchViewController`` examples.
enum FKSearchViewControllerExampleSupport {

  static let fruits: [String] = [
    "Apple", "Apricot", "Banana", "Blackberry", "Blueberry",
    "Cherry", "Coconut", "Date", "Fig", "Grape",
    "Guava", "Kiwi", "Lemon", "Lime", "Mango",
    "Melon", "Orange", "Papaya", "Peach", "Pear",
    "Pineapple", "Plum", "Raspberry", "Strawberry", "Watermelon",
  ]

  static let catalogItems: [String] = FKSearchExampleSupport.catalogItems

  // MARK: - Snapshots

  static func makeFruitItems() -> [FKListItem] {
    fruits.enumerated().map { index, fruit in
      FKListItem.subtitle(
        id: FKListItemID("fruit-\(index)"),
        title: fruit,
        subtitle: "Local filter demo row"
      )
    }
  }

  static func makeFruitBaselineSnapshot() -> FKListSnapshot {
    FKListSnapshot(items: makeFruitItems())
  }

  static func makeCatalogSnapshot() -> FKListSnapshot {
    let items = catalogItems.enumerated().map { index, title in
      FKListItem.subtitle(
        id: FKListItemID("catalog-\(index)"),
        title: title,
        subtitle: "Remote search catalog"
      )
    }
    return FKListSnapshot(items: items)
  }

  static func filteredFruitSnapshot(for query: String) -> FKListSnapshot {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return makeFruitBaselineSnapshot() }
    let filtered = makeFruitItems().filter { item in
      guard case .preset(.subtitle(let row)) = item.kind else { return false }
      return row.title.localizedCaseInsensitiveContains(trimmed)
    }
    return FKListSnapshot(items: filtered)
  }

  // MARK: - Providers

  /// In-memory fruit filter for local mode demos.
  final class FruitLocalFilterProvider: NSObject, FKSearchLocalFilterProviding {
    let baselineSnapshot: FKListSnapshot

    init(baselineSnapshot: FKListSnapshot = FKSearchViewControllerExampleSupport.makeFruitBaselineSnapshot()) {
      self.baselineSnapshot = baselineSnapshot
    }

    func filteredSnapshot(for query: String) -> FKListSnapshot {
      FKSearchViewControllerExampleSupport.filteredFruitSnapshot(for: query)
    }
  }

  /// Mock async API with configurable delay and failure.
  final class MockResultsProvider: NSObject, FKSearchResultsProviding {
    var simulatedDelay: TimeInterval = 1.2
    var failsWhenQueryContains = "error"
    var alwaysFail = false

    func search(query: String) async throws -> FKSearchResultsResponse {
      let nanos = UInt64(max(0, simulatedDelay) * 1_000_000_000)
      try await Task.sleep(nanoseconds: nanos)
      try Task.checkCancellation()

      if alwaysFail || query.localizedCaseInsensitiveContains(failsWhenQueryContains) {
        throw FKSearchError.providerFailed("Mock API failed for \"\(query)\"")
      }

      let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
      let items = FKSearchViewControllerExampleSupport.catalogItems.enumerated().compactMap { index, title -> FKListItem? in
        guard title.localizedCaseInsensitiveContains(trimmed) else { return nil }
        return FKListItem.subtitle(
          id: FKListItemID("remote-\(index)"),
          title: title,
          subtitle: "Remote match"
        )
      }
      return FKSearchResultsResponse(snapshot: FKListSnapshot(items: items))
    }
  }

  // MARK: - Presentation

  static func formatPresentationState(_ state: FKSearchPresentationState) -> String {
    switch state {
    case .idle:
      return "idle"
    case .editing:
      return "editing"
    case .loading(let query):
      return "loading(\"\(query)\")"
    case .results(let query, let count):
      return "results(\"\(query)\", \(count))"
    case .empty(let query, let scenario):
      return "empty(\"\(query)\", \(scenario))"
    case .error(let query, let error):
      return "error(\"\(query)\", \(error))"
    }
  }

  // MARK: - UI helpers

  static func makeEventLogTextView() -> UITextView {
    FKSearchExampleSupport.makeEventLogTextView()
  }

  static func appendLog(_ logView: UITextView, _ line: String) {
    FKSearchExampleSupport.appendLog(logView, line)
  }

  static func embed(
    _ child: UIViewController,
    in host: UIViewController,
    below topAnchor: NSLayoutYAxisAnchor,
    bottomAnchor: NSLayoutYAxisAnchor
  ) {
    host.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: topAnchor),
      child.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    child.didMove(toParent: host)
  }
}

/// Minimal placeholder discovery page for presentation demos — rich idle UI belongs in the host app or FKBusinessKit.
final class FKSearchViewControllerExampleDiscoveryViewController: UIViewController {
  private let titleText: String
  private let items: [String]
  private let onSelect: (String) -> Void

  init(titleText: String, items: [String], onSelect: @escaping (String) -> Void) {
    self.titleText = titleText
    self.items = items
    self.onSelect = onSelect
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let heading = UILabel()
    heading.text = titleText
    heading.font = .preferredFont(forTextStyle: .headline)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    stack.addArrangedSubview(heading)
    for item in items {
      let button = UIButton(type: .system)
      button.setTitle(item, for: .normal)
      button.contentHorizontalAlignment = .leading
      button.addAction(UIAction { [weak self] _ in
        self?.onSelect(item)
      }, for: .touchUpInside)
      stack.addArrangedSubview(button)
    }

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.topAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }
}
