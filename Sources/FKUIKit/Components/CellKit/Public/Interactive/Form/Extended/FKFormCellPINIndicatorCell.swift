import FKCoreKit
import UIKit

/// Secure PIN progress dots without revealing digits (X-61).
@MainActor
public final class FKFormCellPINIndicatorCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellPINIndicatorRow

  private let titleLabel = UILabel()
  private let dotsStack = UIStackView()
  private var dotViews: [UIView] = []

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellPINIndicatorConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellPINIndicatorConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    rebuildDots(count: configuration.slotCount, filled: configuration.filledCount)
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
    accessibilityValue = "\(configuration.filledCount) of \(configuration.slotCount) entered"
  }

  public func configure(with viewModel: FKFormCellPINIndicatorRow) {
    var configuration = viewModel.configuration
    configuration.filledCount = viewModel.filledCount
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    selectionStyle = .none
    accessibilityValue = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    dotsStack.axis = .horizontal
    dotsStack.spacing = 12
    dotsStack.alignment = .center
    dotsStack.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(dotsStack)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      dotsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      dotsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      dotsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      dotsStack.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  private func rebuildDots(count: Int, filled: Int) {
    dotViews.forEach { $0.removeFromSuperview() }
    dotViews.removeAll()
    for index in 0..<count {
      let dot = UIView()
      dot.translatesAutoresizingMaskIntoConstraints = false
      dot.layer.cornerRadius = 8
      dot.backgroundColor = index < filled ? .label : .clear
      dot.layer.borderWidth = 1.5
      dot.layer.borderColor = UIColor.label.cgColor
      NSLayoutConstraint.activate([
        dot.widthAnchor.constraint(equalToConstant: 16),
        dot.heightAnchor.constraint(equalToConstant: 16),
      ])
      dotsStack.addArrangedSubview(dot)
      dotViews.append(dot)
    }
  }
}
