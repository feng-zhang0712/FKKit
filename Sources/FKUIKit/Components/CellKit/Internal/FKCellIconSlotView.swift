import UIKit

/// Reusable leading ``FKIconView`` slot for settings rows.
@MainActor
final class FKCellIconSlotView: UIView {
  private let iconView = FKIconView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(_ content: FKCellIconContent) {
    iconView.configuration = content.configuration
    iconView.symbolName = content.symbolName
    iconView.image = content.image
  }

  func reset() {
    iconView.symbolName = nil
    iconView.image = nil
  }

  private func commonInit() {
    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)
    NSLayoutConstraint.activate([
      iconView.topAnchor.constraint(equalTo: topAnchor),
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
      iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
      iconView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
