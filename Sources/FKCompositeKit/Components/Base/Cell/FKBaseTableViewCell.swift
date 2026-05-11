import UIKit

/// A reusable base class for `UITableViewCell` with a single ``containerView`` content root,
/// consistent hooks for layout and reuse, and optional card-style chrome (corner radius, shadow).
///
/// Subclasses should add subviews inside ``containerView`` (not directly on ``contentView``) and override
/// ``setupUI()``, ``setupStyle()``, and ``bindData(_:)`` (or use ``FKListTableCellConfigurable`` with `configure(with:)` on the subclass).
@MainActor
open class FKBaseTableViewCell: UITableViewCell {

  /// Default reuse identifier derived from the concrete class name.
  open class var reuseIdentifier: String {
    String(describing: self)
  }

  /// Primary content root inside ``contentView``. Subclasses attach custom subviews here.
  public let containerView = UIView()

  /// Insets from ``contentView`` edges to ``containerView`` (design-system spacing).
  public var containerInsets: UIEdgeInsets = .zero {
    didSet { updateContainerConstraints() }
  }

  /// Corner radius applied to ``containerView``. When greater than zero, the container clips subviews.
  public var cornerRadius: CGFloat = .zero {
    didSet {
      containerView.layer.cornerRadius = cornerRadius
      containerView.layer.masksToBounds = cornerRadius > 0
    }
  }

  public var borderWidth: CGFloat = .zero {
    didSet { containerView.layer.borderWidth = borderWidth }
  }

  public var borderColor: UIColor = .clear {
    didSet { containerView.layer.borderColor = borderColor.cgColor }
  }

  public var containerBackgroundColor: UIColor = .clear {
    didSet { containerView.backgroundColor = containerBackgroundColor }
  }

  /// Shadow is applied to the cell ``layer`` (not ``containerView``) so content can stay clipped inside the rounded container.
  public var shadowColor: UIColor = .clear {
    didSet { layer.shadowColor = shadowColor.cgColor }
  }

  public var shadowOpacity: Float = .zero {
    didSet { layer.shadowOpacity = shadowOpacity }
  }

  public var shadowOffset: CGSize = .zero {
    didSet { layer.shadowOffset = shadowOffset }
  }

  public var shadowRadius: CGFloat = .zero {
    didSet { layer.shadowRadius = shadowRadius }
  }

  /// Inset applied when computing ``layer.shadowPath`` (performance tuning for card shadows).
  public var shadowPathInset: CGFloat = .zero {
    didSet { setNeedsLayout() }
  }

  private var containerConstraints: [NSLayoutConstraint] = []
  private var hasPerformedInitialSetup = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    performInitialSetupIfNeeded()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    performInitialSetupIfNeeded()
  }

  open override func awakeFromNib() {
    super.awakeFromNib()
    performInitialSetupIfNeeded()
  }

  open override func prepareForReuse() {
    super.prepareForReuse()
    resetCellContent()
  }

  open override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    selectionDidChange(isSelected: selected, animated: animated)
  }

  open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    highlightDidChange(isHighlighted: highlighted, animated: animated)
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    traitConfigurationDidChange(from: previousTraitCollection)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    updateShadowPathIfNeeded()
  }

  /// Builds subviews and constraints inside ``containerView``.
  open func setupUI() {}

  /// Fonts, colors, and other appearance not tied to a specific model.
  open func setupStyle() {}

  /// Binds a model to the cell. Prefer narrow types in subclasses; `Any` keeps the base generic.
  open func bindData(_ model: Any) {}

  /// Called from ``prepareForReuse()`` after `super`. Override to cancel async work, clear images, or reset transforms.
  open func resetCellContent() {}

  /// Called after ``setSelected(_:animated:)``. Override for custom selected styling.
  open func selectionDidChange(isSelected: Bool, animated: Bool) {}

  /// Called after ``setHighlighted(_:animated:)``. Override for press/highlight styling.
  open func highlightDidChange(isHighlighted: Bool, animated: Bool) {}

  /// Called when Dynamic Type, dark mode, or other traits change. Override to refresh colors and metrics.
  open func traitConfigurationDidChange(from previousTraitCollection: UITraitCollection?) {}

  public func configureSurface(
    cornerRadius: CGFloat,
    borderWidth: CGFloat = .zero,
    borderColor: UIColor = .clear,
    backgroundColor: UIColor = .clear
  ) {
    self.cornerRadius = cornerRadius
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.containerBackgroundColor = backgroundColor
  }

  public func configureShadow(
    color: UIColor,
    opacity: Float,
    offset: CGSize,
    radius: CGFloat,
    pathInset: CGFloat = .zero
  ) {
    shadowColor = color
    shadowOpacity = opacity
    shadowOffset = offset
    shadowRadius = radius
    shadowPathInset = pathInset
  }

  open class func register(to tableView: UITableView) {
    tableView.register(self, forCellReuseIdentifier: reuseIdentifier)
  }

  private func performInitialSetupIfNeeded() {
    guard !hasPerformedInitialSetup else { return }
    hasPerformedInitialSetup = true

    applyDefaultConfiguration()
    setupContainerView()
    setupUI()
    setupStyle()
  }

  private func applyDefaultConfiguration() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    clipsToBounds = false
    contentView.clipsToBounds = false
  }

  private func setupContainerView() {
    containerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(containerView)
    updateContainerConstraints()
  }

  private func updateContainerConstraints() {
    FKBaseReusableCellCore.activateContainerConstraints(
      containerView: containerView,
      contentView: contentView,
      insets: containerInsets,
      storage: &containerConstraints
    )
  }

  private func updateShadowPathIfNeeded() {
    FKBaseReusableCellCore.applyShadowPath(
      to: layer,
      bounds: bounds,
      cornerRadius: cornerRadius,
      shadowPathInset: shadowPathInset,
      shadowOpacity: shadowOpacity,
      shadowRadius: shadowRadius
    )
  }
}

public extension UITableView {
  /// Dequeues a cell of type `T`, registering the class first if needed.
  func fkDequeueCell<T: FKBaseTableViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
    register(type, forCellReuseIdentifier: type.reuseIdentifier)
    let cell = dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath)
    guard let typedCell = cell as? T else {
      fatalError("Failed to dequeue cell \(type.reuseIdentifier) as \(T.self).")
    }
    return typedCell
  }
}
