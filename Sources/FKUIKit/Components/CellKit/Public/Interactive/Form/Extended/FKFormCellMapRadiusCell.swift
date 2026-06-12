import FKCoreKit
import UIKit

/// Static map preview with radius slider (X-72).
@MainActor
public final class FKFormCellMapRadiusCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellMapRadiusRow

  public var onRadiusChanged: ((Double) -> Void)?

  private let titleLabel = UILabel()
  private let mapView = FKCellImageThumbnailView()
  private let radiusLabel = UILabel()
  private let slider = UISlider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellMapRadiusConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellMapRadiusConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    if let mapImage = configuration.mapImage {
      mapView.apply(content: mapImage)
      mapView.isHidden = false
    } else {
      mapView.isHidden = true
    }
    slider.minimumValue = Float(configuration.minimumRadius)
    slider.maximumValue = Float(configuration.maximumRadius)
    slider.value = Float(configuration.radiusMeters)
    slider.isEnabled = configuration.isEnabled
    updateRadiusLabel(configuration.radiusMeters)

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellMapRadiusRow) {
    var configuration = viewModel.configuration
    configuration.radiusMeters = viewModel.radiusMeters
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onRadiusChanged = nil
    mapView.resetForReuse()
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    radiusLabel.font = .preferredFont(forTextStyle: .body)
    mapView.translatesAutoresizingMaskIntoConstraints = false
    slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

    contentView.addSubview(titleLabel)
    contentView.addSubview(mapView)
    contentView.addSubview(radiusLabel)
    contentView.addSubview(slider)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    radiusLabel.translatesAutoresizingMaskIntoConstraints = false
    slider.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      mapView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      mapView.heightAnchor.constraint(equalToConstant: 120),
      radiusLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),
      radiusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      radiusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      slider.topAnchor.constraint(equalTo: radiusLabel.bottomAnchor, constant: 8),
      slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  private func updateRadiusLabel(_ meters: Double) {
    if meters >= 1000 {
      radiusLabel.text = String(format: "%.1f km radius", meters / 1000)
    } else {
      radiusLabel.text = String(format: "%.0f m radius", meters)
    }
  }

  @objc private func sliderChanged() {
    let value = Double(slider.value)
    updateRadiusLabel(value)
    onRadiusChanged?(value)
  }
}
