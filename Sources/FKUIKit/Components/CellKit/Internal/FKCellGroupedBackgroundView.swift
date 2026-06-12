import UIKit

/// Rounded background for inset grouped rows when the table is not using system grouped styling (S-03).
@MainActor
final class FKCellGroupedBackgroundView: UIView {
  private let backgroundPlate = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(_ configuration: FKCellGroupConfiguration?) {
    guard let configuration else {
      isHidden = true
      return
    }
    isHidden = false
    backgroundPlate.backgroundColor = configuration.backgroundColor
    backgroundPlate.layer.cornerRadius = configuration.cornerRadius
    backgroundPlate.layer.cornerCurve = .continuous
    backgroundPlate.layer.maskedCorners = maskedCorners(for: configuration.positionInSection)
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    backgroundColor = .clear
    backgroundPlate.translatesAutoresizingMaskIntoConstraints = false
    addSubview(backgroundPlate)
    NSLayoutConstraint.activate([
      backgroundPlate.topAnchor.constraint(equalTo: topAnchor),
      backgroundPlate.leadingAnchor.constraint(equalTo: leadingAnchor),
      backgroundPlate.trailingAnchor.constraint(equalTo: trailingAnchor),
      backgroundPlate.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    isHidden = true
  }

  private func maskedCorners(for position: FKCellGroupPosition) -> CACornerMask {
    switch position {
    case .single:
      return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    case .first:
      return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    case .middle:
      return []
    case .last:
      return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
  }
}
