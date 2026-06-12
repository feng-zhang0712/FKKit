import FKCoreKit
import UIKit

/// Cloud sync or task status row with spinner or result icon (D-36).
@MainActor
public final class FKCellSyncStatusCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSyncStatusRow

  private let layout = FKCellStandardRowLayout()
  private let statusIconView = UIImageView()
  private let spinner = UIActivityIndicatorView(style: .medium)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellSyncStatusConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellSyncStatusConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.statusText)

    spinner.stopAnimating()
    spinner.isHidden = true
    statusIconView.isHidden = true

    switch configuration.syncState {
    case .idle:
      break
    case .syncing:
      spinner.isHidden = false
      spinner.startAnimating()
      layout.contentStack.setAccessoryViews([spinner])
    case .success:
      statusIconView.image = UIImage(systemName: "checkmark.circle.fill")
      statusIconView.tintColor = .systemGreen
      statusIconView.isHidden = false
      layout.contentStack.setAccessoryViews([statusIconView])
    case .failure:
      statusIconView.image = UIImage(systemName: "xmark.circle.fill")
      statusIconView.tintColor = .systemRed
      statusIconView.isHidden = false
      layout.contentStack.setAccessoryViews([statusIconView])
    }

    if configuration.syncState == .idle {
      layout.contentStack.setAccessoryViews([])
    }

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellSyncStatusRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    spinner.stopAnimating()
    spinner.isHidden = true
    statusIconView.image = nil
    statusIconView.isHidden = true
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    statusIconView.translatesAutoresizingMaskIntoConstraints = false
    statusIconView.contentMode = .scaleAspectFit
    spinner.translatesAutoresizingMaskIntoConstraints = false

    layout.install(in: contentView)
  }
}
