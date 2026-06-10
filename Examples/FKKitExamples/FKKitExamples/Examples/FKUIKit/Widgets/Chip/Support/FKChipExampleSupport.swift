import FKUIKit
import UIKit

/// Shared layout helpers and demo fixtures for Chip widget examples.
enum FKChipExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 8
  }

  static func filterBarItems() -> [FKChipItem] {
    [
      FKChipItem(id: "all", title: "All", isSelected: true),
      FKChipItem(id: "sale", title: "On sale"),
      FKChipItem(id: "new", title: "New", leadingIcon: .symbol(name: "sparkles")),
      FKChipItem(id: "ship", title: "Free shipping", leadingIcon: .symbol(name: "shippingbox")),
      FKChipItem(id: "rating", title: "4★ & up"),
      FKChipItem(id: "brand", title: "Top brands"),
      FKChipItem(id: "eco", title: "Eco-friendly"),
    ]
  }

  static func categoryItems() -> [FKChipItem] {
    [
      FKChipItem(id: "electronics", title: "Electronics"),
      FKChipItem(id: "home", title: "Home"),
      FKChipItem(id: "fashion", title: "Fashion"),
      FKChipItem(id: "sports", title: "Sports"),
      FKChipItem(id: "books", title: "Books"),
      FKChipItem(id: "toys", title: "Toys"),
    ]
  }

  static func inputTokenItems() -> [FKChipItem] {
    [
      FKChipItem(id: "swift", title: "Swift", showsRemoveButton: true),
      FKChipItem(id: "ios", title: "iOS", showsRemoveButton: true),
      FKChipItem(id: "uikit", title: "UIKit", showsRemoveButton: true),
    ]
  }

  static func suggestionItems() -> [FKChipItem] {
    [
      FKChipItem(id: "near", title: "Near me"),
      FKChipItem(id: "open", title: "Open now"),
      FKChipItem(id: "top", title: "Top rated"),
    ]
  }

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

  static func pinScrollView(_ scrollView: UIScrollView, in host: UIView) {
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

  static func eventLogLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = "Events will appear here."
    return label
  }

  static func horizontalRow(spacing: CGFloat = Metrics.rowSpacing, alignment: UIStackView.Alignment = .center) -> UIStackView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = spacing
    row.alignment = alignment
    row.distribution = .fill
    return row
  }

  /// Lays out chip/tag views at their intrinsic widths — avoids ``UIStackView`` ``fill`` stretch.
  static func intrinsicWidthRow(spacing: CGFloat = Metrics.rowSpacing) -> FKChipExampleIntrinsicWidthRowView {
    FKChipExampleIntrinsicWidthRowView(spacing: spacing)
  }

  static func wrappingRow(spacing: CGFloat = Metrics.rowSpacing) -> UIStackView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = spacing
    row.alignment = .center
    row.distribution = .fill
    return row
  }

  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    return row
  }

  static func embedChip(_ chip: FKChip, alignment: UIStackView.Alignment = .leading) -> UIView {
    chip.translatesAutoresizingMaskIntoConstraints = false
    return chip
  }

  static func embedGroup(_ group: FKChipGroup) -> UIView {
    group.translatesAutoresizingMaskIntoConstraints = false
    let host = UIView()
    host.addSubview(group)
    NSLayoutConstraint.activate([
      group.topAnchor.constraint(equalTo: host.topAnchor),
      group.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      group.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      group.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
    return host
  }

  static func embedTag(_ tag: FKTag, alignment: UIStackView.Alignment = .trailing) -> UIView {
    tag.translatesAutoresizingMaskIntoConstraints = false
    return tag
  }
}

/// Single-line row that positions chip/tag subviews at intrinsic size (no horizontal stretch).
final class FKChipExampleIntrinsicWidthRowView: UIView {
  let itemSpacing: CGFloat

  init(spacing: CGFloat) {
    itemSpacing = spacing
    super.init(frame: .zero)
    setContentHuggingPriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func addItem(_ view: UIView) {
    addSubview(view)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    superview?.setNeedsLayout()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil else { return }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    superview?.setNeedsLayout()
  }

  override var intrinsicContentSize: CGSize {
    measuredLayout(maxWidth: nil).size
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let maxWidth: CGFloat?
    if size.width > 0, size.width != UIView.noIntrinsicMetric {
      maxWidth = size.width
    } else {
      maxWidth = nil
    }
    return measuredLayout(maxWidth: maxWidth).size
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    applyMeasuredFrames()
  }

  private func applyMeasuredFrames() {
    let layout = measuredLayout(maxWidth: bounds.width > 0 ? bounds.width : nil)
    var needsAnotherPass = false
    for (view, frame) in layout.frames {
      let size = resolvedItemSize(for: view)
      let resolved = CGRect(
        x: frame.minX,
        y: frame.minY + (frame.height - size.height) / 2,
        width: size.width,
        height: size.height
      )
      if abs(view.frame.width - resolved.width) > 0.5 || abs(view.frame.height - resolved.height) > 0.5 {
        needsAnotherPass = true
      }
      view.frame = resolved
    }
    if needsAnotherPass {
      invalidateIntrinsicContentSize()
      setNeedsLayout()
    }
  }

  private struct MeasuredLayout {
    var size: CGSize
    var frames: [(UIView, CGRect)]
  }

  private func measuredLayout(maxWidth: CGFloat?) -> MeasuredLayout {
    let items = subviews.filter { !$0.isHidden }
    guard !items.isEmpty else { return MeasuredLayout(size: .zero, frames: []) }

    let sizedItems = items.compactMap { view -> (UIView, CGSize)? in
      let size = resolvedItemSize(for: view)
      guard size.width > 0, size.height > 0 else { return nil }
      return (view, size)
    }
    guard !sizedItems.isEmpty else { return MeasuredLayout(size: .zero, frames: []) }

    var contentExtent: CGFloat = 0
    for (index, (_, size)) in sizedItems.enumerated() {
      contentExtent += size.width + (index > 0 ? itemSpacing : 0)
    }

    let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
    let orderedItems = isRTL ? sizedItems.reversed() : sizedItems
    var frames: [(UIView, CGRect)] = []
    var cursorX = isRTL ? contentExtent : CGFloat(0)
    var rowHeight: CGFloat = 0

    for (view, size) in orderedItems {
      let originX: CGFloat
      if isRTL {
        cursorX -= size.width
        originX = cursorX
        cursorX -= itemSpacing
      } else {
        originX = cursorX
        cursorX += size.width + itemSpacing
      }
      frames.append((view, CGRect(origin: CGPoint(x: originX, y: 0), size: size)))
      rowHeight = max(rowHeight, size.height)
    }

    let centeredFrames = frames.map { view, frame in
      (
        view,
        CGRect(
          x: frame.minX,
          y: (rowHeight - frame.height) / 2,
          width: frame.width,
          height: frame.height
        )
      )
    }

    return MeasuredLayout(size: CGSize(width: contentExtent, height: rowHeight), frames: centeredFrames)
  }

  override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
    }
  }

  private func resolvedItemSize(for view: UIView) -> CGSize {
    let natural = CGSize(
      width: UIView.noIntrinsicMetric,
      height: UIView.noIntrinsicMetric
    )
    let fitted = view.sizeThatFits(natural)
    if fitted.width > 0, fitted.height > 0 {
      return fitted
    }
    let intrinsic = view.intrinsicContentSize
    if intrinsic.width > 0, intrinsic.height > 0 {
      return intrinsic
    }
    return .zero
  }
}

@MainActor
class FKChipExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKChipExampleSupport.makeRootScrollStack()
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
    FKChipExampleSupport.pinScrollView(scrollView, in: view)
  }
}
