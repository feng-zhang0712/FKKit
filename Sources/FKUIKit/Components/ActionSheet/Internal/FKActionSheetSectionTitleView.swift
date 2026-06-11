import UIKit

/// Reusable uppercase section title above an action group.
@MainActor
final class FKActionSheetSectionTitleView: UIView {
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    insetsLayoutMarginsFromSafeArea = false

    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(title: String, appearance: FKActionSheetAppearance) {
    label.font = appearance.resolvedSectionTitleFont()
    label.textColor = appearance.sectionTitleColor
    label.text = title.uppercased()
  }
}
