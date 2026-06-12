import FKCoreKit
import UIKit

/// Large-icon metadata header row for About-style screens (D-05).
@MainActor
public final class FKCellInfoCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellInfoRow

  private let layout = FKCellStandardRowLayout()
  private let largeIcon = FKCellLargeIconView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an info row configuration with default appearance.
  public func apply(_ configuration: FKCellInfoConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies an info row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellInfoConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    largeIcon.apply(configuration.icon)
    layout.contentStack.setLeadingContent(largeIcon, width: FKCellLayoutMetrics.infoIconSide)

    let boldFont = FKCellTextStyle(textStyle: .body, weight: .bold).resolvedFont(compatibleWith: traitCollection)
    layout.contentStack.setTitle(configuration.title, font: boldFont)
    layout.contentStack.setSubtitle(configuration.subtitles.joined(separator: "\n"), numberOfLines: 0)
    layout.contentStack.setDetail(nil)
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

    selectionStyle = .none
    accessibilityLabel = ([configuration.title] + configuration.subtitles).joined(separator: ", ")
  }

  public func configure(with viewModel: FKCellInfoRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    largeIcon.reset()
    layout.resetForReuse()
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
  }
}
