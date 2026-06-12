import FKCoreKit
import UIKit
@MainActor
public final class FKCellSliderCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSliderRow
  public var onValueChanged: ((Float) -> Void)?
  private let titleLabel = UILabel(); private let valueLabel = UILabel(); private let slider = UISlider()
  private let separator = FKCellSeparatorLayout.makeDivider(); private var isApplying = false
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellSliderConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellSliderConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    titleLabel.text = configuration.title
    if let vt = configuration.valueText { valueLabel.text = vt; valueLabel.isHidden = false } else { valueLabel.isHidden = true }
    slider.minimumValue = configuration.minimumValue; slider.maximumValue = configuration.maximumValue
    isApplying = true; slider.value = configuration.value; isApplying = false
    slider.isEnabled = configuration.isEnabled
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellSliderRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onValueChanged = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    titleLabel.font = .preferredFont(forTextStyle: .body); valueLabel.font = .preferredFont(forTextStyle: .footnote)
    valueLabel.textColor = .secondaryLabel; slider.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel]); header.axis = .horizontal
    let col = UIStackView(arrangedSubviews: [header, slider]); col.axis = .vertical; col.spacing = 8
    col.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(col); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      col.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      col.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      col.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      col.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      separator.leadingAnchor.constraint(equalTo: col.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
  @objc private func sliderChanged() { guard !isApplying else { return }; onValueChanged?(slider.value) }
}
