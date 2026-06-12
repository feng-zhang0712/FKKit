import FKCoreKit
import UIKit

/// Key-value row with trailing copy control (D-39).
@MainActor
public final class FKCellCopyableValueCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellCopyableValueRow

  /// Called on the main actor after a successful copy.
  public var onCopied: ((String) -> Void)?

  private let layout = FKCellStandardRowLayout()
  private let copyChip = FKCopyChip()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellCopyableValueConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellCopyableValueConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.label)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(
      configuration.value,
      emphasis: .primary
    )
    if configuration.usesMonospaceValue {
      layout.contentStack.detailLabel.font = .monospacedDigitSystemFont(
        ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
        weight: .regular
      )
    }

    if let chipConfig = configuration.copyChipConfiguration {
      copyChip.configuration = chipConfig
    }
    copyChip.text = configuration.value
    copyChip.copyText = configuration.value
    layout.contentStack.setAccessoryViews([copyChip])

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
    accessibilityLabel = "\(configuration.label), \(configuration.value)"
  }

  public func configure(with viewModel: FKCellCopyableValueRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onCopied = nil
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
    wireCopyObserver()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
    wireCopyObserver()
  }

  private func wireCopyObserver() {
    NotificationCenter.default.removeObserver(self, name: .fk_copyChipDidCopy, object: copyChip)
    NotificationCenter.default.addObserver(
      forName: .fk_copyChipDidCopy,
      object: copyChip,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let text = notification.userInfo?[FKCopyChipNotificationKeys.copiedText] as? String
        ?? self.copyChip.copyText
        ?? self.copyChip.text
      self.onCopied?(text)
    }
  }
}
