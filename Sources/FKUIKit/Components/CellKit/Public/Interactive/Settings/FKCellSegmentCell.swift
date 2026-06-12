import FKCoreKit
import UIKit
@MainActor
public final class FKCellSegmentCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSegmentRow
  public var onSelectedIndexChanged: ((Int) -> Void)?
  private let segmentedControl = UISegmentedControl(); private let separator = FKCellSeparatorLayout.makeDivider()
  private var isApplying = false
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellSegmentConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellSegmentConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    segmentedControl.removeAllSegments()
    for (i, title) in configuration.segments.enumerated() { segmentedControl.insertSegment(withTitle: title, at: i, animated: false) }
    isApplying = true
    segmentedControl.selectedSegmentIndex = min(configuration.selectedIndex, max(0, configuration.segments.count - 1))
    isApplying = false
    segmentedControl.isEnabled = configuration.isEnabled
    FKCellSeparatorLayout.updateVisibility(divider: separator, policy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection)
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellSegmentRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onSelectedIndexChanged = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    segmentedControl.translatesAutoresizingMaskIntoConstraints = false; separator.translatesAutoresizingMaskIntoConstraints = false
    segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    contentView.addSubview(segmentedControl); contentView.addSubview(separator)
    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),
      segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      separator.leadingAnchor.constraint(equalTo: segmentedControl.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
  @objc private func segmentChanged() { guard !isApplying else { return }; onSelectedIndexChanged?(segmentedControl.selectedSegmentIndex) }
}
