import FKCoreKit
import UIKit

/// Read-only onboarding step row with numbered indicator and status pill (D-50).
@MainActor
public final class FKCellStepListCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStepListRow

  private let layout = FKCellStandardRowLayout()
  private let stepBadge = UILabel()
  private let statusPill = FKStatusPill()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellStepListConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellStepListConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    configureStepBadge(configuration: configuration)

    layout.contentStack.setLeadingContent(stepBadge, width: 28)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.detail)

    if let status = configuration.statusText {
      statusPill.title = status
      statusPill.style = pillStyle(for: configuration.state)
      layout.contentStack.setAccessoryViews([statusPill])
    } else {
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

  public func configure(with viewModel: FKCellStepListRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    stepBadge.translatesAutoresizingMaskIntoConstraints = false
    stepBadge.font = .preferredFont(forTextStyle: .footnote).withWeight(.semibold)
    stepBadge.textAlignment = .center
    stepBadge.layer.cornerRadius = 14
    stepBadge.clipsToBounds = true
    NSLayoutConstraint.activate([
      stepBadge.widthAnchor.constraint(equalToConstant: 28),
      stepBadge.heightAnchor.constraint(equalToConstant: 28),
    ])
    layout.install(in: contentView)
  }

  private func configureStepBadge(configuration: FKCellStepListConfiguration) {
    switch configuration.state {
    case .completed:
      stepBadge.text = "✓"
      stepBadge.backgroundColor = .systemGreen
      stepBadge.textColor = .white
    case .current:
      stepBadge.text = "\(configuration.stepNumber)"
      stepBadge.backgroundColor = .systemBlue
      stepBadge.textColor = .white
    case .pending:
      stepBadge.text = "\(configuration.stepNumber)"
      stepBadge.backgroundColor = .tertiarySystemFill
      stepBadge.textColor = .secondaryLabel
    }
  }

  private func pillStyle(for state: FKCellStepState) -> FKStatusPillStyle {
    switch state {
    case .completed: return .success
    case .current: return .info
    case .pending: return .neutral
    }
  }
}

private extension UIFont {
  func withWeight(_ weight: UIFont.Weight) -> UIFont {
    let descriptor = fontDescriptor.addingAttributes([
      .traits: [UIFontDescriptor.TraitKey.weight: weight],
    ])
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
