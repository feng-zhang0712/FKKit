import UIKit

/// Trailing meta column for conversation-style feed rows (timestamp + unread badge).
@MainActor
final class FKCellFeedMetaColumnView: UIView {
  let timestampLabel = UILabel()
  let badgeHost = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(timestamp: String?, unread: FKCellUnreadPresentation) {
    if let timestamp, !timestamp.isEmpty {
      timestampLabel.text = timestamp
      timestampLabel.isHidden = false
    } else {
      timestampLabel.text = nil
      timestampLabel.isHidden = true
    }
    FKCellUnreadApplicator.configureBadge(on: badgeHost, presentation: unread)
    badgeHost.isHidden = !unread.isUnread || !unread.showsBadge
  }

  func reset() {
    timestampLabel.text = nil
    timestampLabel.isHidden = true
    badgeHost.fk_clearBadge()
    badgeHost.isHidden = true
  }

  private func commonInit() {
    let stack = UIStackView(arrangedSubviews: [timestampLabel, badgeHost])
    stack.axis = .vertical
    stack.alignment = .trailing
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false

    timestampLabel.font = .preferredFont(forTextStyle: .footnote)
    timestampLabel.textColor = .secondaryLabel
    timestampLabel.adjustsFontForContentSizeCategory = true
    timestampLabel.isHidden = true

    badgeHost.translatesAutoresizingMaskIntoConstraints = false
    badgeHost.setContentHuggingPriority(.required, for: .horizontal)
    NSLayoutConstraint.activate([
      badgeHost.widthAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.unreadDotSize),
      badgeHost.heightAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.unreadDotSize),
    ])

    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      widthAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.metaColumnMinWidth),
    ])
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }
}
