import FKCoreKit
import UIKit

/// Horizontal scrollable emoji reaction picker (X-66).
@MainActor
public final class FKFormCellEmojiPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellEmojiPickerRow

  public var onEmojiSelected: ((String) -> Void)?

  private let titleLabel = UILabel()
  private let scrollView = UIScrollView()
  private let emojiStack = UIStackView()
  private var emojiButtons: [UIButton] = []
  private var selectedEmoji: String?

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellEmojiPickerConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellEmojiPickerConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    selectedEmoji = configuration.selectedEmoji
    rebuildEmojis(configuration.emojis)
    scrollView.isUserInteractionEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellEmojiPickerRow) {
    var configuration = viewModel.configuration
    configuration.selectedEmoji = viewModel.selectedEmoji
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onEmojiSelected = nil
    selectedEmoji = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    scrollView.showsHorizontalScrollIndicator = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    emojiStack.axis = .horizontal
    emojiStack.spacing = 8
    emojiStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(emojiStack)

    contentView.addSubview(titleLabel)
    contentView.addSubview(scrollView)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      scrollView.heightAnchor.constraint(equalToConstant: 44),
      emojiStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      emojiStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      emojiStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      emojiStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      emojiStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
    ])
  }

  private func rebuildEmojis(_ emojis: [String]) {
    emojiButtons.forEach { $0.removeFromSuperview() }
    emojiButtons.removeAll()
    for emoji in emojis {
      let button = UIButton(type: .system)
      button.setTitle(emoji, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 28)
      button.addTarget(self, action: #selector(emojiTapped(_:)), for: .touchUpInside)
      let isSelected = emoji == selectedEmoji
      button.transform = isSelected ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
      emojiStack.addArrangedSubview(button)
      emojiButtons.append(button)
    }
  }

  @objc private func emojiTapped(_ sender: UIButton) {
    guard let emoji = sender.title(for: .normal) else { return }
    selectedEmoji = emoji
    for button in emojiButtons {
      button.transform = button == sender ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
    }
    onEmojiSelected?(emoji)
  }
}
