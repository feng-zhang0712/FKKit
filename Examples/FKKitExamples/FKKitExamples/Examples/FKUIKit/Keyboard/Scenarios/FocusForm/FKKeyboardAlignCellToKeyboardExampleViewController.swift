import UIKit
import FKUIKit

/// Comment-list pattern: tap a row → composer focuses → row bottom aligns to the keyboard / composer top.
final class FKKeyboardAlignCellToKeyboardExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let composer = UIView()
  private let field = FKKeyboardExampleUI.makeTextField(placeholder: "Reply…")
  private var scroller: FKKeyboardFocusScroller?
  private var dismissController: FKKeyboardDismissController?
  private var lastHeaderWidth: CGFloat = 0
  private let comments: [String] = (1...24).map { "Comment #\($0) — tap to reply and align this row above the keyboard." }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Align cell to keyboard"
    view.backgroundColor = .systemBackground
    dismissController = FKKeyboardExampleUI.installTapToDismiss(on: view)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.keyboardDismissMode = .interactive
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.tableHeaderView = makeHeader(width: UIScreen.main.bounds.width)

    composer.translatesAutoresizingMaskIntoConstraints = false
    composer.backgroundColor = .secondarySystemBackground
    let composerStack = FKKeyboardExampleUI.cardStack()
    composerStack.translatesAutoresizingMaskIntoConstraints = false
    composerStack.addArrangedSubview(field)
    composer.addSubview(composerStack)

    view.addSubview(tableView)
    view.addSubview(composer)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: composer.topAnchor),

      composer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      composerStack.topAnchor.constraint(equalTo: composer.topAnchor, constant: 10),
      composerStack.leadingAnchor.constraint(equalTo: composer.leadingAnchor, constant: 16),
      composerStack.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -16),
      composerStack.bottomAnchor.constraint(equalTo: composer.bottomAnchor, constant: -10),
    ])
    FKKeyboardLayout.pinBottom(of: composer, toKeyboardTopOf: view)

    let scroller = FKKeyboardFocusScroller(
      rootView: view,
      scrollView: tableView,
      configuration: .init(
        additionalTopInset: 0,
        keyboardDistanceFromFocusedView: 0,
        appliesKeyboardBottomInset: false
      )
    )
    self.scroller = scroller
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    scroller?.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    scroller?.stop()
    dismissController?.stop()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = tableView.bounds.width
    guard width > 0, abs(width - lastHeaderWidth) > 0.5 else { return }
    lastHeaderWidth = width
    tableView.tableHeaderView = makeHeader(width: width)
  }

  private func makeHeader(width: CGFloat) -> UIView {
    let horizontalInset: CGFloat = 16
    let contentWidth = max(0, width - horizontalInset * 2)

    let title = UILabel()
    title.text = "alignContentRect(_:)"
    title.font = .preferredFont(forTextStyle: .headline)
    title.numberOfLines = 0
    title.frame = CGRect(
      x: horizontalInset,
      y: 16,
      width: contentWidth,
      height: title.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)).height
    )

    let body = UILabel()
    body.text =
      "Tap a comment row. The list offset updates so that row’s bottom aligns to the composer/keyboard (up or down). Rows already at the top are not pulled further with extra top inset."
    body.font = .preferredFont(forTextStyle: .footnote)
    body.textColor = .secondaryLabel
    body.numberOfLines = 0
    let bodyHeight = body.sizeThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude)).height
    body.frame = CGRect(
      x: horizontalInset,
      y: title.frame.maxY + 8,
      width: contentWidth,
      height: bodyHeight
    )

    let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: body.frame.maxY + 16))
    container.addSubview(title)
    container.addSubview(body)
    return container
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    comments.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = comments[indexPath.row]
    config.textProperties.numberOfLines = 0
    cell.contentConfiguration = config
    cell.selectionStyle = .default
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    // Content-space row rect — stable for row 0 / extra-top-inset alignment.
    let rowRect = tableView.rectForRow(at: indexPath)
    scroller?.alignContentRect(rowRect, toKeyboardUsing: nil, additionalBottomInset: 0)
    if field.isFirstResponder {
      // Keyboard already up: alignContentRect applied immediately.
    } else {
      field.becomeFirstResponder()
    }
  }
}
