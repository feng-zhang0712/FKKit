import FKCoreKit
import UIKit

/// Settings row with title, subtitle, and reorder control (I-06).
@MainActor
public final class FKCellReorderCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellReorderRow

  private let layout = FKCellStandardRowLayout()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellReorderConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellReorderConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setDetail(nil)
    layout.accessoryHost.apply(.none, appearance: appearance)
    layout.contentStack.setAccessoryViews([])

    layout.applyChrome(
      .init(
        groupConfiguration: groupConfiguration,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    showsReorderControl = configuration.isEnabled
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellReorderRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    showsReorderControl = false
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  public override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    showsReorderControl = editing
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
  }
}
