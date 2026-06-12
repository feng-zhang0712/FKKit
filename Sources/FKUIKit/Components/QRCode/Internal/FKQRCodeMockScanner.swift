import FKCoreKit
import UIKit

/// Simulator placeholder that mimics a successful scan without camera hardware.
@MainActor
final class FKQRCodeMockScannerView: UIView {
  var onSimulateScan: ((String) -> Void)?

  private let mockRawValue: String
  private let simulateButton = FKButton()

  init(rawValue: String) {
    mockRawValue = rawValue
    super.init(frame: .zero)
    backgroundColor = .secondarySystemBackground

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    titleLabel.text = FKUIKitI18n.string("fkuikit.qrcode.mock.title")

    let descriptionLabel = UILabel()
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.font = .preferredFont(forTextStyle: .body)
    descriptionLabel.textAlignment = .center
    descriptionLabel.numberOfLines = 0
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.text = FKUIKitI18n.string("fkuikit.qrcode.mock.description")

    simulateButton.translatesAutoresizingMaskIntoConstraints = false
    simulateButton.setTitle(
      FKButtonLabelConfiguration(text: FKUIKitI18n.string("fkuikit.qrcode.mock.simulate")),
      for: .normal
    )
    var appearance = FKButtonAppearance.filled(backgroundColor: .systemBlue)
    appearance.cornerStyle = FKButtonCornerStyle(corner: .fixed(10))
    appearance.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
    simulateButton.setAppearances(.init(normal: appearance))
    simulateButton.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    simulateButton.addTarget(self, action: #selector(handleSimulateTapped), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, simulateButton])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .center
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func showScanSucceeded() {
    simulateButton.setTitle(
      FKButtonLabelConfiguration(text: FKUIKitI18n.string("fkuikit.qrcode.scan_success_a11y")),
      for: .normal
    )
    simulateButton.isEnabled = false
  }

  @objc private func handleSimulateTapped() {
    onSimulateScan?(mockRawValue)
  }
}
