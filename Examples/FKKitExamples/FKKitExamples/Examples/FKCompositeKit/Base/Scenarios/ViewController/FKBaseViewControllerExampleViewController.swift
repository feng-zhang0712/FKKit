import FKCompositeKit
import UIKit

/// Hub: lists ``FKBaseViewController`` demos; each row pushes a focused screen so navigation chrome
/// and status bar changes are easy to see in isolation.
final class FKBaseViewControllerExampleViewController: FKBaseTableViewController, UITableViewDataSource, UITableViewDelegate {

  private typealias RowFactory = () -> UIViewController

  private struct Row {
    let title: String
    let subtitle: String
    let makeDestination: RowFactory
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private lazy var sections: [Section] = [
    Section(
      title: "Navigation bar appearance",
      rows: [
        Row(
          title: "System (snapshot restore)",
          subtitle: "Restores chrome captured on first appear; use buttons to hot-swap styles here.",
          makeDestination: { FKBaseExampleNavStyleViewController(style: .system) }
        ),
        Row(
          title: "Opaque default",
          subtitle: "Standard opaque navigation bar.",
          makeDestination: { FKBaseExampleNavStyleViewController(style: .opaqueDefault) }
        ),
        Row(
          title: "Transparent",
          subtitle: "Transparent bar; content can extend under the bar.",
          makeDestination: { FKBaseExampleNavStyleViewController(style: .transparent) }
        ),
        Row(
          title: "Gradient",
          subtitle: "Transparent bar with a gradient background image.",
          makeDestination: { FKBaseExampleNavStyleViewController(style: .gradient) }
        ),
      ]
    ),
    Section(
      title: "Navigation bar behavior",
      rows: [
        Row(
          title: "Large titles",
          subtitle: "prefersLargeTitlesWhileVisible = true",
          makeDestination: { FKBaseExampleLargeTitleViewController() }
        ),
        Row(
          title: "Hide navigation bar",
          subtitle: "navigationBarVisibility = .hidden; edge swipe + explicit pop button",
          makeDestination: { FKBaseExampleNavBarHiddenViewController() }
        ),
      ]
    ),
    Section(
      title: "Status bar",
      rows: [
        Row(
          title: "Default",
          subtitle: "preferredStatusBarAppearance = .default",
          makeDestination: { FKBaseExampleStatusBarViewController(statusBarStyle: .default) }
        ),
        Row(
          title: "Light content",
          subtitle: "Dark chrome + light status bar items",
          makeDestination: { FKBaseExampleStatusBarViewController(statusBarStyle: .lightContent) }
        ),
        Row(
          title: "Dark content",
          subtitle: "Light chrome + dark status bar items (iOS 13+)",
          makeDestination: { FKBaseExampleStatusBarViewController(statusBarStyle: .darkContent) }
        ),
      ]
    ),
    Section(
      title: "State & feedback",
      rows: [
        Row(
          title: "Loading / Empty / Error",
          subtitle: "showLoading, showEmptyView, showErrorView",
          makeDestination: { FKBaseExampleStateOverlaysViewController() }
        ),
        Row(
          title: "Toast",
          subtitle: "showToast (FKToast)",
          makeDestination: { FKBaseExampleToastViewController() }
        ),
      ]
    ),
    Section(
      title: "Gestures & keyboard",
      rows: [
        Row(
          title: "Interactive pop",
          subtitle: "disablesInteractivePopGesture toggle",
          makeDestination: { FKBaseExampleInteractivePopViewController() }
        ),
        Row(
          title: "Keyboard forwarding",
          subtitle: "keyboardWillChange / keyboardWillHide (no toast spam)",
          makeDestination: { FKBaseExampleKeyboardViewController() }
        ),
        Row(
          title: "Tap to dismiss keyboard",
          subtitle: "dismissKeyboardOnTapEnabled toggle",
          makeDestination: { FKBaseExampleTapDismissKeyboardViewController() }
        ),
      ]
    ),
    Section(
      title: "Navigation item & lifecycle",
      rows: [
        Row(
          title: "Custom back button",
          subtitle: "configureBackButton (tap Apply on this screen)",
          makeDestination: { FKBaseExampleCustomBackViewController() }
        ),
        Row(
          title: "Lifecycle logging",
          subtitle: "loadInitialContent, viewDidAppearForTheFirstTime, debugLifecycleLoggingEnabled",
          makeDestination: { FKBaseExampleLifecycleViewController() }
        ),
      ]
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBaseViewController"
  }

  override func setupUI() {
    dismissKeyboardOnTapEnabled = true
    disableScrollViewBounceByDefault = false
    keyboardObservationEnabled = true
    navigationBarVisibility = .visible
    navigationBarStyle = .system
    debugLifecycleLoggingEnabled = true
    logHandler = { event, params in
      print("[FKBaseVC Demo Hub] \(event): \(params)")
    }
    super.setupUI()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func configureTableView(_ tableView: UITableView) {
    super.configureTableView(tableView)
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 8
    }
  }

  // MARK: - UITableViewDataSource

  func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = sections[indexPath.section].rows[indexPath.row].makeDestination()
    navigationController?.pushViewController(vc, animated: true)
  }
}

// MARK: - Navigation style playground (hot-swap on one screen)

private final class FKBaseExampleNavStyleViewController: FKBaseViewController {

  enum DemoStyle {
    case system
    case opaqueDefault
    case transparent
    case gradient
  }

  private let demoStyle: DemoStyle
  private let stack = UIStackView()

  init(style: DemoStyle) {
    self.demoStyle = style
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setupUI() {
    switch demoStyle {
    case .system:
      navigationBarStyle = .system
    case .opaqueDefault:
      navigationBarStyle = .opaqueDefault
    case .transparent:
      navigationBarStyle = .transparent
    case .gradient:
      navigationBarStyle = .gradient(
        colors: [.systemBlue, .systemPurple],
        locations: [0, 1],
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
      )
      preferredStatusBarAppearance = .lightContent
    }
    super.setupUI()
    title = titleForDemo

    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    let hint = UILabel()
    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.text =
      "Styles apply to this screen’s navigationItem; during interactive pop the system interpolates between adjacent screens. Opaque/Transparent keep navigationBar.isTranslucent in sync. Gradient uses light status bar items."
    stack.addArrangedSubview(hint)

    [
      ("Use System", #selector(toSystem)),
      ("Use Opaque", #selector(toOpaque)),
      ("Use Transparent", #selector(toTransparent)),
      ("Use Gradient", #selector(toGradient)),
    ].forEach { stack.addArrangedSubview(makeChromeButton(title: $0.0, action: $0.1)) }
  }

  override func setupConstraints() {
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private var titleForDemo: String {
    switch demoStyle {
    case .system: return "Nav: System"
    case .opaqueDefault: return "Nav: Opaque"
    case .transparent: return "Nav: Transparent"
    case .gradient: return "Nav: Gradient"
    }
  }

  private func makeChromeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = title
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @objc private func toSystem() {
    navigationBarStyle = .system
    preferredStatusBarAppearance = .default
    title = "Nav: System"
  }

  @objc private func toOpaque() {
    navigationBarStyle = .opaqueDefault
    preferredStatusBarAppearance = .default
    title = "Nav: Opaque"
  }

  @objc private func toTransparent() {
    navigationBarStyle = .transparent
    preferredStatusBarAppearance = .default
    title = "Nav: Transparent"
  }

  @objc private func toGradient() {
    navigationBarStyle = .gradient(
      colors: [.systemBlue, .systemPurple],
      locations: [0, 1],
      startPoint: CGPoint(x: 0, y: 0.5),
      endPoint: CGPoint(x: 1, y: 0.5)
    )
    preferredStatusBarAppearance = .lightContent
    title = "Nav: Gradient"
  }
}

// MARK: - Large title

private final class FKBaseExampleLargeTitleViewController: FKBaseViewController {

  override func setupUI() {
    // Large titles rely on scroll-edge vs standard appearance; pinning to opaque default avoids
    // a transient black strip next to the large title on some OS versions when the bar was `.system`.
    navigationBarStyle = .opaqueDefault
    prefersLargeTitlesWhileVisible = true
    super.setupUI()
    title = "Large Title Row"
    navigationItem.largeTitleDisplayMode = .always
  }
}

// MARK: - Hidden navigation bar

private final class FKBaseExampleNavBarHiddenViewController: FKBaseViewController {

  override func setupUI() {
    navigationBarVisibility = .hidden
    super.setupUI()
    title = "Nav Hidden"

    let label = UILabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text =
      "The navigation bar is hidden. Swipe in from the left edge to go back; if the simulator edge gesture is unreliable, use the button below."
    label.font = .preferredFont(forTextStyle: .body)
    view.addSubview(label)

    let pop = UIButton(type: .system)
    pop.configuration = .filled()
    pop.configuration?.title = "popViewController(animated:)"
    pop.translatesAutoresizingMaskIntoConstraints = false
    pop.addTarget(self, action: #selector(popSelf), for: .touchUpInside)
    view.addSubview(pop)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      pop.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
      pop.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])
  }

  @objc private func popSelf() {
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - Status bar

private final class FKBaseExampleStatusBarViewController: FKBaseViewController {

  private let statusBarStyleForDemo: UIStatusBarStyle

  init(statusBarStyle: UIStatusBarStyle) {
    self.statusBarStyleForDemo = statusBarStyle
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setupUI() {
    switch statusBarStyleForDemo {
    case .lightContent:
      // Solid dark bar so `.lightContent` (white status items) reads against the nav + status region.
      navigationBarStyle = .gradient(
        colors: [.black, .black],
        locations: [0, 1],
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
      )
    default:
      navigationBarStyle = .system
    }

    preferredStatusBarAppearance = statusBarStyleForDemo
    super.setupUI()
    title = "Status bar"

    switch statusBarStyleForDemo {
    case .lightContent:
      view.backgroundColor = .black
    case .darkContent:
      view.backgroundColor = .systemBackground
    default:
      view.backgroundColor = .systemBackground
    }

    let label = UILabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = statusBarStyleForDemo == .lightContent ? .white : .label
    label.text = descriptionText
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
    ])
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if statusBarStyleForDemo == .lightContent {
      applyLightStatusBarDemoNavigationChrome()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      navigationController?.navigationBar.tintColor = nil
    }
  }

  private var descriptionText: String {
    switch statusBarStyleForDemo {
    case .lightContent:
      return "preferredStatusBarAppearance = .lightContent\ndark background"
    case .darkContent:
      return "preferredStatusBarAppearance = .darkContent\nlight background"
    case .default:
      return "preferredStatusBarAppearance = .default"
    @unknown default:
      return "preferredStatusBarAppearance (other cases)"
    }
  }

  /// White title + tint on the gradient “black bar” used for the `.lightContent` demo.
  private func applyLightStatusBarDemoNavigationChrome() {
    navigationController?.navigationBar.tintColor = .white
    guard let current = navigationItem.standardAppearance else { return }
    let base = current.copy()
    base.titleTextAttributes = [.foregroundColor: UIColor.white]
    base.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    navigationItem.standardAppearance = base
    navigationItem.scrollEdgeAppearance = base
    navigationItem.compactAppearance = base
    if #available(iOS 15.0, *) {
      navigationItem.compactScrollEdgeAppearance = base
    }
  }
}

// MARK: - State overlays

private final class FKBaseExampleStateOverlaysViewController: FKBaseViewController {

  private let stack = UIStackView()

  override func setupUI() {
    super.setupUI()
    title = "State views"

    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    [
      ("Show Loading (1.2s)", #selector(handleShowLoading)),
      ("Show Empty", #selector(handleShowEmpty)),
      ("Show Error + Retry", #selector(handleShowError)),
      ("Hide All State Views", #selector(handleHideAllStates)),
    ].forEach { stack.addArrangedSubview(makeButton(title: $0.0, action: $0.1)) }

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = title
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @objc private func handleShowLoading() {
    showLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.hideLoading()
    }
  }

  @objc private func handleShowEmpty() {
    showEmptyView(message: "No list data. Pull to refresh or change filters.")
  }

  @objc private func handleShowError() {
    showErrorView(message: "Request failed. Try again.", retryTitle: "Retry") { [weak self] in
      self?.showToast("Retry tapped")
      self?.hideErrorView()
    }
  }

  @objc private func handleHideAllStates() {
    hideLoading()
    hideEmptyView()
    hideErrorView()
  }
}

// MARK: - Toast

private final class FKBaseExampleToastViewController: FKBaseViewController {

  override func setupUI() {
    super.setupUI()
    title = "Toast"

    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = "Show Toast"
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handleToast), for: .touchUpInside)
    view.addSubview(button)
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  @objc private func handleToast() {
    showToast("Toast via FKToast from FKBaseViewController.")
  }
}

// MARK: - Interactive pop

private final class FKBaseExampleInteractivePopViewController: FKBaseViewController {

  private let stack = UIStackView()

  override func setupUI() {
    super.setupUI()
    title = "Interactive pop"

    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.text =
      "When disabled, edge and content-area swipes should not start a pop (iOS 26+ also uses interactiveContentPopGestureRecognizer). Re-enable to restore immediately."
    stack.addArrangedSubview(label)

    stack.addArrangedSubview(makeButton(title: "Disable interactive pop", action: #selector(disablePop)))
    stack.addArrangedSubview(makeButton(title: "Enable interactive pop", action: #selector(enablePop)))

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.title = title
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @objc private func disablePop() {
    disablesInteractivePopGesture = true
    showToast("Interactive pop disabled")
  }

  @objc private func enablePop() {
    disablesInteractivePopGesture = false
    showToast("Interactive pop enabled")
  }
}

// MARK: - Keyboard

private final class FKBaseExampleKeyboardViewController: FKBaseViewController {

  private let field = UITextField()
  private let status = UILabel()

  override func setupUI() {
    super.setupUI()
    title = "Keyboard"

    status.numberOfLines = 0
    status.font = .preferredFont(forTextStyle: .footnote)
    status.textColor = .secondaryLabel
    status.text = "Focus the field and watch the keyboard height hint below."
    status.translatesAutoresizingMaskIntoConstraints = false

    field.borderStyle = .roundedRect
    field.placeholder = "Tap to show keyboard"
    field.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(field)
    view.addSubview(status)

    NSLayoutConstraint.activate([
      field.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      status.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 16),
      status.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      status.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  override func keyboardWillChange(to frame: CGRect, duration: TimeInterval, curve: UIView.AnimationCurve) {
    status.text = "keyboardWillChange — visible keyboard height ≈ \(Int(frame.intersection(view.bounds).height)) pt"
  }

  override func keyboardWillHide(duration: TimeInterval, curve: UIView.AnimationCurve) {
    status.text = "keyboardWillHide"
  }
}

// MARK: - Tap to dismiss

private final class FKBaseExampleTapDismissKeyboardViewController: FKBaseViewController {

  private let field = UITextField()
  private let toggle = UISwitch()

  override func setupUI() {
    dismissKeyboardOnTapEnabled = true
    super.setupUI()
    title = "Tap dismiss"

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.alignment = .center
    row.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = "dismissKeyboardOnTapEnabled"
    label.font = .preferredFont(forTextStyle: .body)

    toggle.isOn = true
    toggle.addTarget(self, action: #selector(tapDismissChanged), for: .valueChanged)

    row.addArrangedSubview(label)
    row.addArrangedSubview(toggle)

    field.borderStyle = .roundedRect
    field.placeholder = "Focus then tap outside"
    field.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(row)
    view.addSubview(field)

    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

      field.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 16),
      field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  @objc private func tapDismissChanged() {
    dismissKeyboardOnTapEnabled = toggle.isOn
    showToast(toggle.isOn ? "Tap outside to dismiss: on" : "Tap outside to dismiss: off")
  }
}

// MARK: - Custom back

private final class FKBaseExampleCustomBackViewController: FKBaseViewController {

  override func setupUI() {
    super.setupUI()
    title = "Custom back"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Apply",
      style: .plain,
      target: self,
      action: #selector(apply)
    )

    let label = UILabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .secondaryLabel
    label.text = "Tap Apply (top trailing) to call configureBackButton(title:)."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  @objc private func apply() {
    configureBackButton(title: "Back")
    showToast("Custom back button configured")
  }
}

// MARK: - Lifecycle

private final class FKBaseExampleLifecycleViewController: FKBaseViewController {

  private let label = UILabel()

  override func setupUI() {
    debugLifecycleLoggingEnabled = true
    logHandler = { event, params in
      print("[FKBaseVC Demo Lifecycle] \(event): \(params)")
    }
    super.setupUI()
    title = "Lifecycle"

    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.text =
      "debugLifecycleLoggingEnabled is on. Check the Xcode console for FKLogger output; loadInitialContent and viewDidAppearForTheFirstTime each run once."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  override func loadInitialContent() {
    super.loadInitialContent()
    print("[FKBaseVC Demo Lifecycle] loadInitialContent()")
  }

  override func viewDidAppearForTheFirstTime(_ animated: Bool) {
    super.viewDidAppearForTheFirstTime(animated)
    print("[FKBaseVC Demo Lifecycle] viewDidAppearForTheFirstTime(animated: \(animated))")
  }
}
