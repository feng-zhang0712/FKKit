import UIKit

/// Hosts ``FKCellTrailingContent`` for status and badge rows.
@MainActor
final class FKCellTrailingContentHostView: UIView {
  private var accessoryHostStorage: FKCellAccessoryHostView?
  private var hostConstraints: [NSLayoutConstraint] = []

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
      accessoryHostStorage?.apply(.none, appearance: appearance)
      detachAccessoryHost()

    case .disclosure:
      resolvedAccessoryHost().apply(.disclosureIndicator, appearance: appearance)

    case let .value(text):
      resolvedAccessoryHost().apply(.value(text), appearance: appearance)

    case let .statusPill(configuration):
      resolvedAccessoryHost().apply(.statusPill(configuration), appearance: appearance)

    case let .badge(configuration):
      resolvedAccessoryHost().apply(.badge(configuration), appearance: appearance, badgeCount: badgeCount)

    case let .custom(id):
      resolvedAccessoryHost().apply(.custom(id: id), appearance: appearance)
    }
  }

  func reset() {
    accessoryHostStorage?.apply(.none, appearance: .default)
    detachAccessoryHost()
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  private func resolvedAccessoryHost() -> FKCellAccessoryHostView {
    if let accessoryHostStorage { return accessoryHostStorage }
    let host = FKCellAccessoryHostView()
    host.translatesAutoresizingMaskIntoConstraints = false
    addSubview(host)
    hostConstraints = [
      host.topAnchor.constraint(equalTo: topAnchor),
      host.leadingAnchor.constraint(equalTo: leadingAnchor),
      host.trailingAnchor.constraint(equalTo: trailingAnchor),
      host.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]
    NSLayoutConstraint.activate(hostConstraints)
    accessoryHostStorage = host
    return host
  }

  private func detachAccessoryHost() {
    accessoryHostStorage?.removeFromSuperview()
    accessoryHostStorage = nil
    NSLayoutConstraint.deactivate(hostConstraints)
    hostConstraints = []
  }
}
