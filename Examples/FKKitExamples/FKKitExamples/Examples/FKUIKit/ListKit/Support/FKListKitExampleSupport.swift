import FKUIKit
import UIKit

// MARK: - Feed API

/// Simulated paginated feed for ListKit refresh/load-more demos.
enum FKListKitExampleFeedAPI {
  static let pageSize = 8
  /// Fills modern phone viewports so the load-more footer is visible and auto-trigger can arm.
  static let paginationDemoPageSize = 15
  static let maxPages = 4

  static func fetch(
    page: Int,
    delay: TimeInterval = 0.75,
    itemsPerPage: Int = pageSize
  ) async throws -> (titles: [String], hasMorePages: Bool) {
    let nanos = UInt64(max(0, delay) * 1_000_000_000)
    try await Task.sleep(nanoseconds: nanos)
    guard page >= 1 else { return ([], false) }
    let count = max(1, itemsPerPage)
    let titles = (1 ... count).map { "Page \(page) · Item \($0)" }
    let hasMore = page < maxPages
    return (titles, hasMore)
  }

  static func makeItems(titles: [String], page: Int) -> [FKListItem] {
    titles.enumerated().map { index, title in
      FKListItem(
        id: FKListItemID("feed-\(page)-\(index)"),
        kind: .preset(.subtitle(FKListSubtitleRow(title: title, subtitle: "Pull to refresh · scroll for more")))
      )
    }
  }

  static func makeSnapshot(titles: [String], page: Int, sectionID: FKListSectionID = "main") -> FKListSnapshot {
    FKListSnapshot(sections: [FKListSection(id: sectionID, items: makeItems(titles: titles, page: page))])
  }

  static func makeFetchResult(titles: [String], page: Int, hasMorePages: Bool) -> FKListFetchResult {
    FKListFetchResult(snapshot: makeSnapshot(titles: titles, page: page), hasMorePages: hasMorePages)
  }
}

// MARK: - Table header

@MainActor
enum FKListKitExampleTableHeader {
  /// Sizes and assigns a self-layout table header without triggering temporary height constraints.
  static func apply(_ container: UIView, to tableView: UITableView) {
    let width = resolvedWidth(for: tableView)
    // Provisional non-zero height avoids `_UITemporaryLayoutHeight == 0` conflicts while fitting.
    container.frame = CGRect(x: 0, y: 0, width: width, height: 44)
    container.setNeedsLayout()
    container.layoutIfNeeded()
    let height = fittedHeight(for: container, width: width)
    container.frame = CGRect(x: 0, y: 0, width: width, height: height)
    tableView.tableHeaderView = container
    tableView.tableHeaderView = container
  }

  /// Re-fits the current header after the table view lays out (call from `viewDidLayoutSubviews`).
  static func refresh(_ tableView: UITableView) {
    guard let container = tableView.tableHeaderView else { return }
    let width = resolvedWidth(for: tableView)
    guard width > 0 else { return }
    let height = fittedHeight(for: container, width: width)
    guard abs(container.frame.width - width) > 0.5 || abs(container.frame.height - height) > 0.5 else { return }
    container.frame = CGRect(x: 0, y: 0, width: width, height: height)
    tableView.tableHeaderView = container
  }

  /// Re-fits only when the table width changed (e.g. rotation).
  static func refreshIfWidthChanged(_ tableView: UITableView) {
    guard let container = tableView.tableHeaderView else { return }
    let width = resolvedWidth(for: tableView)
    guard width > 0, abs(container.frame.width - width) > 0.5 else { return }
    refresh(tableView)
  }

  private static func resolvedWidth(for tableView: UITableView) -> CGFloat {
    if tableView.bounds.width > 0 { return tableView.bounds.width }
    if let width = tableView.superview?.bounds.width, width > 0 { return width }
    return UIScreen.main.bounds.width
  }

  private static func fittedHeight(for container: UIView, width: CGFloat) -> CGFloat {
    container.frame.size.width = width
    container.setNeedsLayout()
    container.layoutIfNeeded()
    let height = container.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height
    return max(ceil(height), 1)
  }
}

// MARK: - Status strip

/// Bottom status strip used by delegate and lifecycle demos.
@MainActor
enum FKListKitExampleStatusStrip {
  static func install(on viewController: UIViewController, above scrollView: UIScrollView) -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "Waiting for events…"
    label.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
    ])
    scrollView.contentInset.bottom += 28
    scrollView.verticalScrollIndicatorInsets.bottom += 28
    return label
  }

  static func append(_ line: String, to label: UILabel?, resizingTableHeader tableView: UITableView? = nil) {
    guard let label else { return }
    let prefix = label.text == "Waiting for events…" ? "" : (label.text ?? "") + "\n"
    label.text = prefix + line
    if let tableView {
      FKListKitExampleTableHeader.refresh(tableView)
    }
  }

  /// Compact event log pinned above the table (avoids bottom inset that can interfere with swipes).
  static func installInTableHeader(_ tableView: UITableView, placeholder: String = "Waiting for events…") -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = placeholder
    label.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = .systemBackground
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
    ])

    FKListKitExampleTableHeader.apply(container, to: tableView)
    return label
  }
}

// MARK: - Icons

enum FKListKitExampleIcons {
  static func remoteURL(id: Int) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/80/80")!
  }
}
