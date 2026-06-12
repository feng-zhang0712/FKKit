import FKCoreKit
import UIKit

/// File manager row with type icon and metadata (D-45).
@MainActor
public final class FKCellFileCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellFileRow

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellFileConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellFileConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(configuration.fileIcon)
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.fileName)
    var subtitle = configuration.meta
    if let cloud = configuration.cloudState {
      let cloudText: String
      switch cloud {
      case .localOnly: cloudText = "Local only"
      case .synced: cloudText = "Synced"
      case .uploading: cloudText = "Uploading"
      }
      subtitle = subtitle.map { "\(cloudText) · \($0)" } ?? cloudText
    }
    layout.contentStack.setSubtitle(subtitle)

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews(configuration.showsDisclosure ? [layout.accessoryHost] : [])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.fileName
  }

  public func configure(with viewModel: FKCellFileRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
