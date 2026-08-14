import UIKit

/// Card chrome that wraps multiple selection rows (for example ``FKCheckbox`` lists).
public struct FKSelectionListChromeConfiguration: @unchecked Sendable, Equatable {
  public var cornerRadius: CGFloat
  public var borderWidth: CGFloat
  public var borderColor: UIColor
  public var backgroundColor: UIColor
  public var separatorColor: UIColor
  public var separatorInset: NSDirectionalEdgeInsets
  public var showsError: Bool
  public var errorBorderColor: UIColor

  public init(
    cornerRadius: CGFloat = 12,
    borderWidth: CGFloat = 1,
    borderColor: UIColor = .separator,
    backgroundColor: UIColor = .secondarySystemGroupedBackground,
    separatorColor: UIColor = .separator,
    separatorInset: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 16),
    showsError: Bool = false,
    errorBorderColor: UIColor = .systemRed
  ) {
    self.cornerRadius = max(0, cornerRadius)
    self.borderWidth = max(0, borderWidth)
    self.borderColor = borderColor
    self.backgroundColor = backgroundColor
    self.separatorColor = separatorColor
    self.separatorInset = separatorInset
    self.showsError = showsError
    self.errorBorderColor = errorBorderColor
  }
}

/// Rounded card with inset separators for stacking selection controls.
@MainActor
public final class FKSelectionListChrome: UIView {
  public var configuration: FKSelectionListChromeConfiguration {
    didSet { applyChrome(); setNeedsLayout() }
  }

  private let stack = UIStackView()
  private var separators: [FKDivider] = []
  private var arranged: [UIView] = []

  public override init(frame: CGRect) {
    configuration = FKSelectionControlDefaults.listChrome
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    configuration = FKSelectionControlDefaults.listChrome
    super.init(coder: coder)
    commonInit()
  }

  public init(configuration: FKSelectionListChromeConfiguration = FKSelectionControlDefaults.listChrome) {
    self.configuration = configuration
    super.init(frame: .zero)
    commonInit()
  }

  private func commonInit() {
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 0
    addSubview(stack)
    applyChrome()
  }

  /// Replaces arranged row views and rebuilds separators between them.
  public func setArrangedControls(_ views: [UIView]) {
    arranged.forEach { $0.removeFromSuperview() }
    separators.forEach { $0.removeFromSuperview() }
    stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
    arranged = views
    separators.removeAll()

    for (index, view) in views.enumerated() {
      stack.addArrangedSubview(view)
      if index < views.count - 1 {
        let divider = FKDivider(configuration: makeDividerConfiguration())
        separators.append(divider)
        stack.addArrangedSubview(divider)
      }
    }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    stack.frame = bounds
  }

  public override var intrinsicContentSize: CGSize {
    let fitting = stack.systemLayoutSizeFitting(
      CGSize(width: bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(width: UIView.noIntrinsicMetric, height: fitting.height)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyChrome()
  }

  private func applyChrome() {
    backgroundColor = configuration.backgroundColor
    layer.cornerRadius = configuration.cornerRadius
    layer.cornerCurve = .continuous
    layer.borderWidth = configuration.borderWidth
    let border = configuration.showsError ? configuration.errorBorderColor : configuration.borderColor
    layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
    clipsToBounds = true

    let dividerConfiguration = makeDividerConfiguration()
    for divider in separators {
      divider.configuration = dividerConfiguration
    }
  }

  private func makeDividerConfiguration() -> FKDividerConfiguration {
    let inset = configuration.separatorInset
    return FKDividerConfiguration(
      direction: .horizontal,
      color: configuration.separatorColor,
      contentInsets: UIEdgeInsets(
        top: inset.top,
        left: inset.leading,
        bottom: inset.bottom,
        right: inset.trailing
      ),
      isPixelPerfect: true
    )
  }
}
