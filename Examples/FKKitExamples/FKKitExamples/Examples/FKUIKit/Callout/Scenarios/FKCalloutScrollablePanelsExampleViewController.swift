import UIKit
import FKUIKit

/// UITableView and UIScrollView content hosted in ``FKPopover/show(customView:)``.
final class FKCalloutScrollablePanelsExampleViewController: FKCalloutExampleBaseViewController {
  private let tableAnchor = FKCalloutExampleUI.anchorButton("Table anchor")
  private let scrollAnchor = FKCalloutExampleUI.anchorButton("Scroll anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scrollable panels"

    let anchors = UIStackView(arrangedSubviews: [
      FKCalloutExampleUI.row([tableAnchor, scrollAnchor]),
    ])
    anchors.axis = .vertical

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchors",
        description: "Each anchor shows a different scrollable customView popover with a capped height.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchors, height: 120)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show UITableView panel") { [weak self] in
        self?.showTablePanel()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show UIScrollView panel") { [weak self] in
        self?.showScrollPanel()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "FKPopover.show(customView:) · fixed width, max height, internal scrolling.",
        body: controls
      )
    )
  }

  private func showTablePanel() {
    presentPanel(
      anchoredTo: tableAnchor,
      placement: .bottom,
      matchesAnchorWidth: true,
      customView: { FKCalloutScrollableTableContentView() },
      logLabel: "UITableView"
    )
  }

  private func showScrollPanel() {
    presentPanel(
      anchoredTo: scrollAnchor,
      placement: .bottom,
      matchesAnchorWidth: true,
      customView: { FKCalloutScrollableScrollContentView() },
      logLabel: "UIScrollView"
    )
  }

  private func presentPanel(
    anchoredTo anchor: UIView,
    placement: FKCalloutPlacement,
    matchesAnchorWidth: Bool,
    customView: @escaping @MainActor () -> UIView,
    logLabel: String
  ) {
    anchor.layoutIfNeeded()
    var config = FKCalloutConfiguration.popoverDefault(placement: placement)
    config.anchorAlignment = .center
    config.matchesAnchorWidth = matchesAnchorWidth
    if matchesAnchorWidth {
      config.maxWidth = anchor.bounds.width
    }
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

    FKPopover.show(
      customView: customView,
      anchoredTo: anchor,
      placement: placement,
      configuration: config
    )
    log("FKPopover.show(customView:) · \(logLabel)")
  }
}

/// Fixed-size table for callout sizing.
@MainActor
private final class FKCalloutScrollableTableContentView: UIView, UITableViewDataSource, UITableViewDelegate {
  static let size = CGSize(width: 280, height: 220)

  private let tableView = UITableView(frame: .zero, style: .plain)
  private let rows = (1...24).map { "Row \($0)" }

  override var intrinsicContentSize: CGSize {
    Self.size
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 44
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
      tableView.topAnchor.constraint(equalTo: topAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = rows[indexPath.row]
    cell.contentConfiguration = config
    return cell
  }
}

/// Vertical scroll stack for callout sizing.
@MainActor
private final class FKCalloutScrollableScrollContentView: UIView {
  static let size = CGSize(width: 300, height: 200)

  override var intrinsicContentSize: CGSize {
    Self.size
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    (1...10).forEach { index in
      let card = UIView()
      card.backgroundColor = .secondarySystemFill
      card.layer.cornerRadius = 8
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .subheadline)
      label.text = "Scroll block \(index) — drag inside the popover."
      label.numberOfLines = 0
      label.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
        label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
        label.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
        label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
      ])
      stack.addArrangedSubview(card)
    }

    scrollView.addSubview(stack)
    addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 4),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -4),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -4),
      stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -8),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}
