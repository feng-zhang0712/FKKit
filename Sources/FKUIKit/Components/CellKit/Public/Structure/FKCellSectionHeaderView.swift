import UIKit

/// Section header styling for inset grouped lists (S-01).
public enum FKCellSectionHeaderTextTransform: Sendable, Equatable {
  /// Uppercases ASCII letters in the header title.
  case automaticUppercase
  /// Preserves the supplied title string.
  case preserved
}

/// Configuration for ``FKCellSectionHeaderView``.
public struct FKCellSectionHeaderConfiguration: Sendable, Equatable {
  public var title: String
  public var textTransform: FKCellSectionHeaderTextTransform
  public var usesHeaderAccessibilityTrait: Bool

  /// Creates a section header configuration.
  public init(
    title: String,
    textTransform: FKCellSectionHeaderTextTransform = .automaticUppercase,
    usesHeaderAccessibilityTrait: Bool = true
  ) {
    self.title = title
    self.textTransform = textTransform
    self.usesHeaderAccessibilityTrait = usesHeaderAccessibilityTrait
  }
}

/// Settings-style section header placed above grouped card content.
@MainActor
public final class FKCellSectionHeaderView: UITableViewHeaderFooterView {
  public static var reuseIdentifier: String { String(describing: Self.self) }

  private let titleLabel = UILabel()
  private var configuration = FKCellSectionHeaderConfiguration(title: "")
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies header content and optional appearance overrides.
  public func apply(
    _ configuration: FKCellSectionHeaderConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.configuration = configuration
    self.appearance = appearance
    refreshContent()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      refreshContent()
    }
  }

  private func commonInit() {
    contentView.backgroundColor = .clear
    backgroundView = UIView()
    backgroundView?.backgroundColor = .clear

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    titleLabel.adjustsFontForContentSizeCategory = true
    contentView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(
        equalTo: contentView.topAnchor,
        constant: FKCellLayoutMetrics.sectionHeaderTopInset
      ),
      titleLabel.leadingAnchor.constraint(
        equalTo: contentView.layoutMarginsGuide.leadingAnchor,
        constant: FKCellLayoutMetrics.horizontalContentInset
      ),
      titleLabel.trailingAnchor.constraint(
        equalTo: contentView.layoutMarginsGuide.trailingAnchor,
        constant: -FKCellLayoutMetrics.horizontalContentInset
      ),
      titleLabel.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -FKCellLayoutMetrics.sectionHeaderBottomInset
      ),
    ])
  }

  private func refreshContent() {
    let displayTitle: String
    switch configuration.textTransform {
    case .automaticUppercase:
      displayTitle = configuration.title.uppercased(with: Locale.current)
    case .preserved:
      displayTitle = configuration.title
    }
    titleLabel.text = displayTitle
    titleLabel.font = appearance.subtitleTextStyle.resolvedFont(compatibleWith: traitCollection)
    titleLabel.textColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)

    accessibilityLabel = displayTitle
    if configuration.usesHeaderAccessibilityTrait {
      accessibilityTraits = [.header]
    } else {
      accessibilityTraits = []
    }
  }
}
