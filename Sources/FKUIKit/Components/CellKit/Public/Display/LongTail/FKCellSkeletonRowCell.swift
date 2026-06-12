import FKCoreKit
import UIKit
@MainActor
public final class FKCellSkeletonRowCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSkeletonRowRow
  private let skeletonContainer = FKSkeletonContainerView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellSkeletonRowConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellSkeletonRowConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    skeletonContainer.subviews.forEach { if $0 !== skeletonContainer { $0.removeFromSuperview() } }
    for i in 0..<configuration.lineCount {
      let line = FKSkeletonView(); line.translatesAutoresizingMaskIntoConstraints = false
      skeletonContainer.addSubview(line)
      NSLayoutConstraint.activate([
        line.leadingAnchor.constraint(equalTo: skeletonContainer.leadingAnchor),
        line.trailingAnchor.constraint(equalTo: skeletonContainer.trailingAnchor, constant: CGFloat(-(i * 40))),
        line.topAnchor.constraint(equalTo: skeletonContainer.topAnchor, constant: CGFloat(i * 20)),
        line.heightAnchor.constraint(equalToConstant: 14),
      ])
    }
    backgroundColor = appearance.cellBackgroundColor; contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled; selectionStyle = .none
  }
  public func configure(with viewModel: FKCellSkeletonRowRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    skeletonContainer.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(skeletonContainer)
    NSLayoutConstraint.activate([
      skeletonContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      skeletonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      skeletonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      skeletonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      skeletonContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }
}
