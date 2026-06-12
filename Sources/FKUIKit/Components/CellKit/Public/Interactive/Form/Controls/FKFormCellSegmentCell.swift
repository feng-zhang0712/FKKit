import FKCoreKit
import UIKit

/// Label plus ``UISegmentedControl`` form row (X-38, F-07).
@MainActor
public final class FKFormCellSegmentCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormSegmentRow

  /// Called when the selected segment index changes.
  public var onSelectionChanged: ((Int) -> Void)?

  private let rootStack = UIStackView()
  private let labelView = UILabel()
  private let segmentedControl = UISegmentedControl()
  private var isApplyingConfiguration = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSegmentConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellSegmentConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    if let label = configuration.label, !label.isEmpty {
      labelView.text = label
      labelView.isHidden = false
    } else {
      labelView.isHidden = true
    }

    segmentedControl.removeAllSegments()
    for (index, title) in configuration.segmentTitles.enumerated() {
      segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
    }
    isApplyingConfiguration = true
    if configuration.selectedIndex >= 0, configuration.selectedIndex < configuration.segmentTitles.count {
      segmentedControl.selectedSegmentIndex = configuration.selectedIndex
    } else {
      segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
    }
    isApplyingConfiguration = false
    segmentedControl.isEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormSegmentRow) {
    var configuration = viewModel.configuration
    configuration.selectedIndex = viewModel.selectedIndex
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSelectionChanged = nil
    segmentedControl.removeAllSegments()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    labelView.font = .preferredFont(forTextStyle: .footnote)
    labelView.textColor = .secondaryLabel
    labelView.isHidden = true

    segmentedControl.addTarget(self, action: #selector(handleSegmentChanged), for: .valueChanged)

    rootStack.addArrangedSubview(labelView)
    rootStack.addArrangedSubview(segmentedControl)

    contentView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
    ])
  }

  @objc private func handleSegmentChanged() {
    guard !isApplyingConfiguration else { return }
    onSelectionChanged?(segmentedControl.selectedSegmentIndex)
  }
}
