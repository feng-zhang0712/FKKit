import FKCoreKit
import UIKit

/// Embedded ``FKSearchField`` row for list section filters (X-26–X-29).
@MainActor
public final class FKFormCellSearchCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormSearchRow

  /// Called on every keystroke.
  public var onTextChanged: ((String) -> Void)?
  /// Called after debounce when enabled.
  public var onSearchQueryChanged: ((String) -> Void)?
  /// Called when the user submits search.
  public var onSubmit: ((String) -> Void)?
  /// Called when the user clears the field.
  public var onClear: (() -> Void)?
  /// Called when the user taps the trailing search button (rounded style).
  public var onSearchButtonTapped: (() -> Void)?
  /// Called when the user taps the voice icon (voice style).
  public var onVoiceTapped: (() -> Void)?

  private let searchField = FKSearchField()
  private let accessoryButton = UIButton(type: .system)
  private let categoryLabel = UILabel()
  private let rootStack = UIStackView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSearchConfiguration) {
    apply(configuration, appearance: .default, text: searchField.text)
  }

  public func apply(
    _ configuration: FKFormCellSearchConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    text: String = ""
  ) {
    searchField.apply(configuration.searchFieldConfiguration)
    searchField.placeholder = configuration.placeholder
    searchField.setText(text, options: .silent)
    searchField.isEnabled = configuration.isEnabled

    categoryLabel.isHidden = true
    accessoryButton.isHidden = true

    switch configuration.style {
    case .capsule, .prefixCategory:
      if case let .prefixCategory(title) = configuration.style {
        categoryLabel.text = title
        categoryLabel.isHidden = false
      }
    case .roundedWithButton:
      accessoryButton.setTitle("Search", for: .normal)
      accessoryButton.isHidden = false
    case .withVoiceIcon:
      accessoryButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
      accessoryButton.isHidden = false
    }

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.placeholder
  }

  public func configure(with viewModel: FKFormSearchRow) {
    apply(viewModel.configuration, text: viewModel.text)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    onSearchQueryChanged = nil
    onSubmit = nil
    onClear = nil
    onSearchButtonTapped = nil
    onVoiceTapped = nil
    searchField.setText("", options: .silent)
    selectionStyle = .none
    accessibilityLabel = nil
    wireSearchCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .horizontal
    rootStack.alignment = .center
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    categoryLabel.font = .preferredFont(forTextStyle: .footnote)
    categoryLabel.textColor = .secondaryLabel
    categoryLabel.setContentHuggingPriority(.required, for: .horizontal)
    categoryLabel.isHidden = true

    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchField.setContentHuggingPriority(.defaultLow, for: .horizontal)

    accessoryButton.translatesAutoresizingMaskIntoConstraints = false
    accessoryButton.setContentHuggingPriority(.required, for: .horizontal)
    accessoryButton.addTarget(self, action: #selector(handleAccessoryTap), for: .touchUpInside)
    accessoryButton.isHidden = true

    rootStack.addArrangedSubview(categoryLabel)
    rootStack.addArrangedSubview(searchField)
    rootStack.addArrangedSubview(accessoryButton)

    contentView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      searchField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])

    wireSearchCallbacks()
  }

  private func wireSearchCallbacks() {
    searchField.callbacks = FKSearchCallbacks(
      onTextChanged: { [weak self] text in
        self?.onTextChanged?(text)
      },
      onSearchQueryChanged: { [weak self] text in
        self?.onSearchQueryChanged?(text)
      },
      onSubmit: { [weak self] text in
        self?.onSubmit?(text)
      },
      onClear: { [weak self] in
        self?.onClear?()
      }
    )
  }

  @objc private func handleAccessoryTap() {
    if accessoryButton.currentImage != nil {
      onVoiceTapped?()
    } else {
      onSearchButtonTapped?()
    }
  }
}
