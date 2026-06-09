import FKUIKit
import UIKit

/// Shared layout, sample data, and embedding helpers for FlowVisualization examples.
enum FKFlowVisualizationExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
  }

  // MARK: - Scroll shell

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true
    scroll.keyboardDismissMode = .onDrag
    scroll.contentInsetAdjustmentBehavior = .always

    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = Metrics.cardSpacing
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = Metrics.screenMargins
    scroll.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
    ])

    return (scroll, stack)
  }

  static func pinScrollView(_ scrollView: UIScrollView, contentStack: UIStackView, in host: UIView) {
    host.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
  }

  static func sectionContainer(title: String) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel])
    stack.axis = .vertical
    stack.spacing = Metrics.cardContentSpacing
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = Metrics.cardPadding
    stack.backgroundColor = .secondarySystemGroupedBackground
    stack.layer.cornerRadius = 14
    stack.layer.cornerCurve = .continuous
    stack.clipsToBounds = true
    return stack
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func monospacedLogLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "Events will appear here."
    return label
  }

  static func appendLog(_ line: String, to label: UILabel) {
    let stamp = Self.timeFormatter.string(from: Date())
    let entry = "[\(stamp)] \(line)"
    if label.text == "Events will appear here." {
      label.text = entry
    } else {
      label.text = [label.text, entry].compactMap { $0 }.joined(separator: "\n")
    }
  }

  static func embedStepIndicator(_ indicator: FKStepIndicator, minHeight: CGFloat = 88) -> UIView {
    let wrapper = UIView()
    indicator.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(indicator)
    NSLayoutConstraint.activate([
      indicator.topAnchor.constraint(equalTo: wrapper.topAnchor),
      indicator.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
      indicator.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
      indicator.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
      wrapper.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),
    ])
    return wrapper
  }

  static func embedTimeline(_ timeline: FKTimeline, minHeight: CGFloat = 200) -> UIView {
    let wrapper = UIView()
    timeline.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(timeline)
    NSLayoutConstraint.activate([
      timeline.topAnchor.constraint(equalTo: wrapper.topAnchor),
      timeline.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
      timeline.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
      timeline.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
      wrapper.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),
    ])
    return wrapper
  }

  static func primaryButton(title: String, action: UIAction) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    let button = UIButton(configuration: config, primaryAction: action)
    return button
  }

  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }

  // MARK: - Sample data

  static func checkoutItems() -> [FKFlowStepItem] {
    [
      FKFlowStepItem(id: "cart", title: "Cart", subtitle: "Review items"),
      FKFlowStepItem(id: "address", title: "Address", subtitle: "Shipping info"),
      FKFlowStepItem(id: "payment", title: "Payment", subtitle: "Card or wallet"),
      FKFlowStepItem(id: "done", title: "Done", subtitle: "Confirmation"),
    ]
  }

  static func onboardingItems() -> [FKFlowStepItem] {
    [
      FKFlowStepItem(id: "profile", title: "Profile"),
      FKFlowStepItem(id: "prefs", title: "Preferences"),
      FKFlowStepItem(id: "notify", title: "Notifications"),
      FKFlowStepItem(id: "finish", title: "Finish"),
    ]
  }

  static func manyStepTitles(count: Int) -> [FKFlowStepItem] {
    (1 ... count).map { index in
      FKFlowStepItem(id: "step-\(index)", title: "Step \(index)")
    }
  }

  static func logisticsItems() -> [FKFlowStepItem] {
    let shipped = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    let transit = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    return [
      FKFlowStepItem(
        id: "ordered",
        title: "Order placed",
        subtitle: "Warehouse processing",
        timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        state: .completed
      ),
      FKFlowStepItem(
        id: "shipped",
        title: "Shipped",
        subtitle: "Left fulfillment center",
        caption: "Tracking #: FK-2048-A",
        timestamp: shipped,
        state: .completed
      ),
      FKFlowStepItem(
        id: "transit",
        title: "In transit",
        subtitle: "Estimated delivery tomorrow",
        timestamp: transit,
        state: .current
      ),
      FKFlowStepItem(
        id: "delivered",
        title: "Delivered",
        subtitle: "Signature required",
        state: .upcoming
      ),
    ]
  }

  static func auditSections() -> [FKTimelineSection] {
    [
      FKTimelineSection(
        id: "today",
        title: "Today",
        items: [
          FKFlowStepItem(
            id: "login",
            title: "Signed in",
            caption: "User agent: FKKitExamples/1.0 (iOS)",
            formattedTimestamp: "10:14 AM",
            state: .completed
          ),
          FKFlowStepItem(
            id: "settings",
            title: "Changed notification settings",
            caption: "Push enabled for order updates.",
            formattedTimestamp: "11:02 AM",
            state: .completed
          ),
        ]
      ),
      FKTimelineSection(
        id: "yesterday",
        title: "Yesterday",
        items: [
          FKFlowStepItem(
            id: "payment",
            title: "Payment method updated",
            caption: "Visa •••• 4242 added. Previous card removed.",
            formattedTimestamp: "4:30 PM",
            state: .completed
          ),
        ]
      ),
    ]
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    return formatter
  }()
}

@MainActor
class FKFlowVisualizationScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKFlowVisualizationExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKFlowVisualizationExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)
  }
}
