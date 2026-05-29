#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKRatingControl`` / ``FKRatingConfiguration``.
public struct FKRatingControlRepresentable: UIViewRepresentable {
  @Binding public var value: Double
  public var configuration: FKRatingConfiguration
  public var minimumValue: Double
  public var maximumValue: Double
  public var animateChanges: Bool
  public var onValueChanged: ((Double) -> Void)?

  public init(
    value: Binding<Double>,
    configuration: FKRatingConfiguration = FKRatingDefaults.configuration,
    minimumValue: Double = 0,
    maximumValue: Double = 5,
    animateChanges: Bool = true,
    onValueChanged: ((Double) -> Void)? = nil
  ) {
    _value = value
    self.configuration = configuration
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    self.animateChanges = animateChanges
    self.onValueChanged = onValueChanged
  }

  @MainActor
  public final class Coordinator: NSObject {
    var onValueChanged: ((Double) -> Void)?

    @objc func handleValueChanged(_ sender: FKRatingControl) {
      let newValue = sender.value
      onValueChanged?(newValue)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> FKRatingControl {
    let control = FKRatingControl(
      configuration: configuration,
      value: value,
      minimumValue: minimumValue,
      maximumValue: maximumValue
    )
    context.coordinator.onValueChanged = { newValue in
      if value != newValue {
        value = newValue
      }
      onValueChanged?(newValue)
    }
    control.addTarget(context.coordinator, action: #selector(Coordinator.handleValueChanged(_:)), for: .valueChanged)
    return control
  }

  public func updateUIView(_ uiView: FKRatingControl, context: Context) {
    context.coordinator.onValueChanged = { newValue in
      if value != newValue {
        value = newValue
      }
      onValueChanged?(newValue)
    }
    uiView.configuration = configuration
    uiView.minimumValue = minimumValue
    uiView.maximumValue = maximumValue
    if uiView.value != value {
      uiView.setValue(value, animated: animateChanges, sendsControlEvents: false)
    }
  }
}
#endif
