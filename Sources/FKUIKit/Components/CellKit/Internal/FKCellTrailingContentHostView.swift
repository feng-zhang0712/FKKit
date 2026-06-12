import UIKit

/// Hosts ``FKCellTrailingContent`` for status and badge rows.
@MainActor
final class FKCellTrailingContentHostView: UIView {
  private let accessoryHost = FKCellAccessoryHostView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    _ content: FKCellTrailingContent,
    badgeCount: Int = 0,
    appearance: FKCellAppearanceConfiguration
  ) {
    switch content {
    case .none:
      accessoryHost.apply(.none, appearance: appearance)
    case .disclosure:
      accessoryHost.apply(.disclosureIndicator, appearance: appearance)
    case let .value(text):
      accessoryHost.apply(.value(text), appearance: appearance)
    case let .statusPill(configuration):
      accessoryHost.apply(.statusPill(configuration), appearance: appearance)
    case let .badge(configuration):
      accessoryHost.apply(.badge(configuration), appearance: appearance, badgeCount: badgeCount)
    case .custom(let id):
      accessoryHost.apply(.custom(id: id), appearance: appearance)
    }
  }

  func reset() {
    accessoryHost.apply(.none, appearance: .default)
  }

  private func commonInit() {
    accessoryHost.translatesAutoresizingMaskIntoConstraints = false
    addSubview(accessoryHost)
    NSLayoutConstraint.activate([
      accessoryHost.topAnchor.constraint(equalTo: topAnchor),
      accessoryHost.leadingAnchor.constraint(equalTo: leadingAnchor),
      accessoryHost.trailingAnchor.constraint(equalTo: trailingAnchor),
      accessoryHost.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
