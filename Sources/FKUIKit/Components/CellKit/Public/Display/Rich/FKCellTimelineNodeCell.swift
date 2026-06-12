import FKCoreKit
import UIKit

/// Timeline axis row with node state and stacked content (D-32).
@MainActor
public final class FKCellTimelineNodeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellTimelineNodeRow

  private let groupedBackgroundHost = FKCellGroupedBackgroundHosting()
  private let rootStack = UIStackView()
  private let axisColumn = UIView()
  private let topLine = UIView()
  private let nodeView = UIView()
  private let bottomLine = UIView()
  private let contentStack = UIStackView()
  private let titleRow = UIStackView()
  private let titleLabel = UILabel()
  private let timestampLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellTimelineNodeConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellTimelineNodeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.title
    if let subtitle = configuration.subtitle, !subtitle.isEmpty {
      subtitleLabel.text = subtitle
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.isHidden = true
    }
    if let timestamp = configuration.timestamp, !timestamp.isEmpty {
      timestampLabel.text = timestamp
      timestampLabel.isHidden = false
    } else {
      timestampLabel.isHidden = true
    }

    applyNodeState(configuration.state)
    topLine.isHidden = configuration.isFirst
    bottomLine.isHidden = configuration.isLast

    groupedBackgroundHost.apply(nil, in: contentView)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellTimelineNodeRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    subtitleLabel.text = nil
    subtitleLabel.isHidden = true
    timestampLabel.text = nil
    timestampLabel.isHidden = true
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    rootStack.axis = .horizontal
    rootStack.alignment = .top
    rootStack.spacing = 12
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    axisColumn.translatesAutoresizingMaskIntoConstraints = false
    topLine.translatesAutoresizingMaskIntoConstraints = false
    nodeView.translatesAutoresizingMaskIntoConstraints = false
    bottomLine.translatesAutoresizingMaskIntoConstraints = false
    topLine.backgroundColor = .separator
    bottomLine.backgroundColor = .separator
    nodeView.layer.cornerRadius = 8
    nodeView.layer.borderWidth = 2

    contentStack.axis = .vertical
    contentStack.spacing = 4
    titleRow.axis = .horizontal
    titleRow.alignment = .firstBaseline
    titleRow.spacing = 8

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    timestampLabel.font = .preferredFont(forTextStyle: .caption1)
    timestampLabel.textColor = .secondaryLabel
    timestampLabel.setContentHuggingPriority(.required, for: .horizontal)

    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.isHidden = true

    separator.translatesAutoresizingMaskIntoConstraints = false
    axisColumn.addSubview(topLine)
    axisColumn.addSubview(nodeView)
    axisColumn.addSubview(bottomLine)
    titleRow.addArrangedSubview(titleLabel)
    titleRow.addArrangedSubview(timestampLabel)
    contentStack.addArrangedSubview(titleRow)
    contentStack.addArrangedSubview(subtitleLabel)
    rootStack.addArrangedSubview(axisColumn)
    rootStack.addArrangedSubview(contentStack)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      axisColumn.widthAnchor.constraint(equalToConstant: 20),
      topLine.topAnchor.constraint(equalTo: axisColumn.topAnchor),
      topLine.centerXAnchor.constraint(equalTo: axisColumn.centerXAnchor),
      topLine.widthAnchor.constraint(equalToConstant: 2),
      topLine.bottomAnchor.constraint(equalTo: nodeView.topAnchor, constant: -4),

      nodeView.centerXAnchor.constraint(equalTo: axisColumn.centerXAnchor),
      nodeView.centerYAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: -6),
      nodeView.widthAnchor.constraint(equalToConstant: 16),
      nodeView.heightAnchor.constraint(equalToConstant: 16),

      bottomLine.topAnchor.constraint(equalTo: nodeView.bottomAnchor, constant: 4),
      bottomLine.centerXAnchor.constraint(equalTo: axisColumn.centerXAnchor),
      bottomLine.widthAnchor.constraint(equalToConstant: 2),
      bottomLine.bottomAnchor.constraint(equalTo: axisColumn.bottomAnchor),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  private func applyNodeState(_ state: FKCellTimelineNodeState) {
    switch state {
    case .completed:
      nodeView.backgroundColor = .systemBlue
      nodeView.layer.borderColor = UIColor.systemBlue.cgColor
    case .current:
      nodeView.backgroundColor = .clear
      nodeView.layer.borderColor = UIColor.systemBlue.cgColor
    case .upcoming:
      nodeView.backgroundColor = .clear
      nodeView.layer.borderColor = UIColor.separator.cgColor
    case .failed:
      nodeView.backgroundColor = .systemRed
      nodeView.layer.borderColor = UIColor.systemRed.cgColor
    }
  }
}
