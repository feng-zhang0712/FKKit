import UIKit

/// A reusable base class for `UICollectionViewCell` mirroring ``FKBaseTableViewCell`` patterns:
/// a ``containerView`` root, reuse/t hooks, and optional card-style chrome.
///
/// Override ``setupUI()`` and ``setupStyle()`` for structure and appearance; use ``bindData(_:)`` or
/// ``FKListCollectionCellConfigurable`` `configure(with:)` on concrete subclasses.
@MainActor
open class FKBaseCollectionViewCell: UICollectionViewCell {

  open class var reuseIdentifier: String {
    String(describing: self)
  }

  public let containerView = UIView()

  public var containerInsets: UIEdgeInsets = .zero {
    didSet { updateContainerConstraints() }
  }

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

  public var shadowPathInset: CGFloat = .zero {
    didSet { setNeedsLayout() }
  }

  private var containerConstraints: [NSLayoutConstraint] = []
  private var hasPerformedInitialSetup = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
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

  open override var isHighlighted: Bool {
    didSet {
      if isHighlighted != oldValue {
        highlightStateDidChange(isHighlighted: isHighlighted)
      }
    }
  }

  open override var isSelected: Bool {
    didSet {
      if isSelected != oldValue {
        selectionStateDidChange(isSelected: isSelected)
      }
    }
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    traitConfigurationDidChange(from: previousTraitCollection)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    updateShadowPathIfNeeded()
  }

  open func setupUI() {}

  open func setupStyle() {}

  open func bindData(_ model: Any) {}

  /// Called from ``prepareForReuse()`` after `super`. Override to clear images, cancel tasks, or reset transforms.
  open func resetCellContent() {}

  /// Invoked when ``isHighlighted`` changes (collection selection/highlight semantics).
  open func highlightStateDidChange(isHighlighted: Bool) {}

  /// Invoked when ``isSelected`` changes.
  open func selectionStateDidChange(isSelected: Bool) {}

  /// Called when Dynamic Type, dark mode, or other traits change.
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

  open class func register(to collectionView: UICollectionView) {
    collectionView.register(self, forCellWithReuseIdentifier: reuseIdentifier)
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

public extension UICollectionView {
  /// Dequeues a cell of type `T`, registering the class first if needed.
  func fkDequeueCell<T: FKBaseCollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
    register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    let cell = dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath)
    guard let typedCell = cell as? T else {
      fatalError("Failed to dequeue cell \(type.reuseIdentifier) as \(T.self).")
    }
    return typedCell
  }
}
