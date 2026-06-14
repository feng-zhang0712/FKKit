import UIKit

/// Frame-managed `tableHeaderView` installation for ``FKSearchBar`` (avoids Auto Layout conflicts).
@MainActor
enum FKSearchTableHeaderInstaller {
  static func install(searchBar: FKSearchBar, in tableView: UITableView, container: UIView? = nil) {
    let host = container ?? makeContainer(searchBar: searchBar)
    apply(host, to: tableView)
  }

  static func refresh(_ tableView: UITableView) {
    guard let container = tableView.tableHeaderView else { return }
    let width = resolvedWidth(for: tableView)
    guard width > 0 else { return }
    let height = fittedHeight(for: container, width: width)
    guard abs(container.frame.width - width) > 0.5 || abs(container.frame.height - height) > 0.5 else { return }
    container.frame = CGRect(x: 0, y: 0, width: width, height: height)
    tableView.tableHeaderView = container
  }

  private static func makeContainer(searchBar: FKSearchBar) -> UIView {
    let container = UIView()
    container.backgroundColor = .systemBackground
    container.addSubview(searchBar)
    return container
  }

  private static func apply(_ container: UIView, to tableView: UITableView) {
    let width = resolvedWidth(for: tableView)
    container.frame = CGRect(x: 0, y: 0, width: width, height: 44)
    layoutSearchBar(in: container, width: width)
    container.setNeedsLayout()
    container.layoutIfNeeded()
    let height = fittedHeight(for: container, width: width)
    container.frame = CGRect(x: 0, y: 0, width: width, height: height)
    tableView.tableHeaderView = container
  }

  private static func layoutSearchBar(in container: UIView, width: CGFloat) {
    guard let searchBar = container.subviews.first else { return }
    let horizontalInset: CGFloat = 16
    let verticalInset: CGFloat = 8
    let barWidth = width - horizontalInset * 2
    let barHeight = searchBar.sizeThatFits(
      CGSize(width: barWidth, height: UIView.layoutFittingCompressedSize.height)
    ).height
    searchBar.frame = CGRect(
      x: horizontalInset,
      y: verticalInset,
      width: barWidth,
      height: barHeight
    )
  }

  private static func resolvedWidth(for tableView: UITableView) -> CGFloat {
    if tableView.bounds.width > 0 { return tableView.bounds.width }
    if let width = tableView.superview?.bounds.width, width > 0 { return width }
    return UIScreen.main.bounds.width
  }

  private static func fittedHeight(for container: UIView, width: CGFloat) -> CGFloat {
    if let searchBar = container.subviews.first {
      layoutSearchBar(in: container, width: width)
      let verticalInset: CGFloat = 8
      return max(ceil(searchBar.frame.maxY + verticalInset), 1)
    }
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
