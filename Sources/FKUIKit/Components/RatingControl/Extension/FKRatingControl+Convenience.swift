import UIKit

public extension FKRatingControl {
  /// Creates a read-only star rating with the given value.
  static func readOnlyStars(
    value: Double,
    itemCount: Int = 5,
    filledColor: UIColor = .systemYellow
  ) -> FKRatingControl {
    var configuration = FKRatingDefaults.configuration
    configuration.interaction.mode = .readOnly
    configuration.layout.itemCount = itemCount
    configuration.appearance.filledColor = filledColor
    configuration.appearance.iconStyle = .preset(.star)
    return FKRatingControl(
      configuration: configuration,
      value: value,
      maximumValue: Double(itemCount)
    )
  }

  /// Creates an interactive star rating with the given step size.
  static func interactiveStars(
    value: Double = 0,
    itemCount: Int = 5,
    step: FKRatingStep = .whole,
    filledColor: UIColor = .systemYellow
  ) -> FKRatingControl {
    var configuration = FKRatingDefaults.configuration
    configuration.interaction.mode = .interactive
    configuration.interaction.step = step
    configuration.layout.itemCount = itemCount
    configuration.appearance.filledColor = filledColor
    configuration.appearance.iconStyle = .preset(.star)
    return FKRatingControl(
      configuration: configuration,
      value: value,
      maximumValue: Double(itemCount)
    )
  }
}
