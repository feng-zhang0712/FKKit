import UIKit

/// Fixed-width leading checkmark slot for selection rows (I-03).
@MainActor
final class FKCellLeadingCheckmarkSlot: UIView {
  private let checkmarkView: UIImageView = {
    let image = UIImage(
      systemName: "checkmark",
      withConfiguration: UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
    )
    let view = UIImageView(image: image)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.tintColor = .systemBlue
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(isSelected: Bool, reservesSpaceWhenUnselected: Bool) {
    checkmarkView.isHidden = !isSelected
    isHidden = !reservesSpaceWhenUnselected && !isSelected
  }

  func reset() {
    checkmarkView.isHidden = true
    isHidden = false
  }

  private func commonInit() {
    addSubview(checkmarkView)
    NSLayoutConstraint.activate([
      checkmarkView.centerXAnchor.constraint(equalTo: centerXAnchor),
      checkmarkView.centerYAnchor.constraint(equalTo: centerYAnchor),
      widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.checkmarkColumnWidth),
    ])
  }
}
