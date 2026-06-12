import FKCoreKit
import UIKit

/// Horizontal 0–10 NPS score selector (X-65).
@MainActor
public final class FKFormCellNPSScaleCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellNPSScaleRow

  /// Called when the user selects a score.
  public var onScoreSelected: ((Int) -> Void)?

  private let titleLabel = UILabel()
  private let scoresStack = UIStackView()
  private var scoreButtons: [UIButton] = []
  private var storedConfiguration = FKFormCellNPSScaleConfiguration()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellNPSScaleConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellNPSScaleConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    storedConfiguration = configuration
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    rebuildScoreButtons(min: configuration.minimumScore, max: configuration.maximumScore)
    updateSelection(configuration.selectedScore)
    scoresStack.isUserInteractionEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellNPSScaleRow) {
    var configuration = viewModel.configuration
    configuration.selectedScore = viewModel.selectedScore
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onScoreSelected = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    titleLabel.numberOfLines = 0

    scoresStack.axis = .horizontal
    scoresStack.distribution = .fillEqually
    scoresStack.spacing = 4
    scoresStack.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(scoresStack)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      scoresStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      scoresStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      scoresStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      scoresStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      scoresStack.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  private func rebuildScoreButtons(min: Int, max: Int) {
    scoreButtons.forEach { $0.removeFromSuperview() }
    scoreButtons.removeAll()
    guard min <= max else { return }
    for score in min...max {
      let button = UIButton(type: .system)
      button.setTitle("\(score)", for: .normal)
      button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
      button.layer.cornerRadius = 6
      button.layer.borderWidth = 1
      button.layer.borderColor = UIColor.separator.cgColor
      button.tag = score
      button.addTarget(self, action: #selector(scoreTapped(_:)), for: .touchUpInside)
      scoresStack.addArrangedSubview(button)
      scoreButtons.append(button)
    }
  }

  private func updateSelection(_ selected: Int?) {
    for button in scoreButtons {
      let isSelected = button.tag == selected
      button.backgroundColor = isSelected ? .systemBlue : .clear
      button.setTitleColor(isSelected ? .white : .label, for: .normal)
    }
  }

  @objc private func scoreTapped(_ sender: UIButton) {
    updateSelection(sender.tag)
    onScoreSelected?(sender.tag)
  }
}
