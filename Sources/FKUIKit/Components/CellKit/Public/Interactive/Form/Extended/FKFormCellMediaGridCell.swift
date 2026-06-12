import FKCoreKit
import UIKit

/// Three-column media upload grid with add tile (X-63).
@MainActor
public final class FKFormCellMediaGridCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellMediaGridRow

  public var onAddTap: (() -> Void)?
  public var onRemoveAtIndex: ((Int) -> Void)?

  private let titleLabel = UILabel()
  private let gridStack = UIStackView()
  private var thumbnailViews: [FKCellImageThumbnailView] = []
  private let addButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellMediaGridConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellMediaGridConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    rebuildGrid(images: configuration.images, maxCount: configuration.maxCount)
    addButton.isEnabled = configuration.isEnabled && configuration.images.count < configuration.maxCount
    isUserInteractionEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellMediaGridRow) {
    var configuration = viewModel.configuration
    configuration.images = viewModel.images
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onAddTap = nil
    onRemoveAtIndex = nil
    thumbnailViews.forEach { $0.resetForReuse() }
    thumbnailViews.removeAll()
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    gridStack.axis = .vertical
    gridStack.spacing = 8
    gridStack.translatesAutoresizingMaskIntoConstraints = false

    addButton.setTitle("+ Add", for: .normal)
    addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

    contentView.addSubview(titleLabel)
    contentView.addSubview(gridStack)
    contentView.addSubview(addButton)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      gridStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      addButton.topAnchor.constraint(equalTo: gridStack.bottomAnchor, constant: 8),
      addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  private func rebuildGrid(images: [FKCellImageContent], maxCount: Int) {
    gridStack.arrangedSubviews.forEach { row in
      gridStack.removeArrangedSubview(row)
      row.removeFromSuperview()
    }
    thumbnailViews.forEach { $0.resetForReuse() }
    thumbnailViews.removeAll()

    let items = images + (images.count < maxCount ? [nil] : [])
    var row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually

    for (index, content) in items.enumerated() {
      if index > 0 && index % 3 == 0 {
        gridStack.addArrangedSubview(row)
        row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
      }
      if let content {
        let thumb = FKCellImageThumbnailView()
        thumb.apply(content: content)
        thumb.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          thumb.heightAnchor.constraint(equalToConstant: 72),
        ])
        thumbnailViews.append(thumb)
        row.addArrangedSubview(thumb)
      } else {
        let placeholder = UIButton(type: .system)
        placeholder.setImage(UIImage(systemName: "plus"), for: .normal)
        placeholder.layer.cornerRadius = 8
        placeholder.layer.borderWidth = 1
        placeholder.layer.borderColor = UIColor.separator.cgColor
        placeholder.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([placeholder.heightAnchor.constraint(equalToConstant: 72)])
        row.addArrangedSubview(placeholder)
      }
    }
    if !row.arrangedSubviews.isEmpty {
      gridStack.addArrangedSubview(row)
    }
  }

  @objc private func addTapped() {
    onAddTap?()
  }
}
