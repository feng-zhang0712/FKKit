import FKCoreKit
import UIKit
@MainActor
public final class FKCellPreviewPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPreviewPickerRow
  public var onTap: (() -> Void)?
  private let layout = FKCellStandardRowLayout(); private let iconSlot = FKCellIconSlotView()
  private let previewView = UIImageView(); private let pickerIndicator = UIImageView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellPreviewPickerConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellPreviewPickerConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    if let icon = configuration.icon { iconSlot.apply(icon); layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth) }
    else { layout.contentStack.setLeadingContent(nil, width: 0) }
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setDetail(configuration.value, emphasis: .secondary)
    previewView.image = configuration.previewImage; previewView.isHidden = configuration.previewImage == nil
    let trailing = UIStackView(arrangedSubviews: [previewView, pickerIndicator]); trailing.axis = .horizontal; trailing.spacing = 8; trailing.alignment = .center
    layout.contentStack.setAccessoryViews([trailing])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.isEnabled ? .default : .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellPreviewPickerRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onTap = nil; iconSlot.reset(); previewView.image = nil; layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .default; layout.install(in: contentView)
    previewView.contentMode = .scaleAspectFill; previewView.clipsToBounds = true; previewView.layer.cornerRadius = 6
    previewView.translatesAutoresizingMaskIntoConstraints = false
    pickerIndicator.image = UIImage(systemName: "chevron.up.chevron.down"); pickerIndicator.tintColor = .tertiaryLabel
    NSLayoutConstraint.activate([previewView.widthAnchor.constraint(equalToConstant: 36), previewView.heightAnchor.constraint(equalToConstant: 36)])
  }
}
