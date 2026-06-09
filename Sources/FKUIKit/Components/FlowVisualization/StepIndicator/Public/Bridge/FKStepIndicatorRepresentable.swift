#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKStepIndicator``.
public struct FKStepIndicatorRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var currentStepIndex: Int?
  public var configuration: FKStepIndicatorConfiguration
  public var isLoading: Bool
  public var currentStepProgress: CGFloat
  public var onStepSelected: ((Int) -> Void)?

  public init(
    items: [FKFlowStepItem],
    currentStepIndex: Int? = nil,
    configuration: FKStepIndicatorConfiguration = FKStepIndicatorDefaults.configuration,
    isLoading: Bool = false,
    currentStepProgress: CGFloat = 0,
    onStepSelected: ((Int) -> Void)? = nil
  ) {
    self.items = items
    self.currentStepIndex = currentStepIndex
    self.configuration = configuration
    self.isLoading = isLoading
    self.currentStepProgress = currentStepProgress
    self.onStepSelected = onStepSelected
  }

  public func makeUIView(context: Context) -> FKStepIndicator {
    let indicator = FKStepIndicator(configuration: configuration, items: items, currentStepIndex: currentStepIndex)
    indicator.isLoading = isLoading
    indicator.currentStepProgress = currentStepProgress
    indicator.onStepSelected = { index, _ in
      onStepSelected?(index)
    }
    return indicator
  }

  public func updateUIView(_ uiView: FKStepIndicator, context: Context) {
    if uiView.configuration != configuration {
      uiView.configuration = configuration
    }
    if uiView.items != items {
      uiView.setItems(items, animated: false)
    }
    if uiView.currentStepIndex != currentStepIndex {
      uiView.currentStepIndex = currentStepIndex
    }
    if uiView.isLoading != isLoading {
      uiView.isLoading = isLoading
    }
    if uiView.currentStepProgress != currentStepProgress {
      uiView.currentStepProgress = currentStepProgress
    }
    uiView.onStepSelected = { index, _ in
      onStepSelected?(index)
    }
  }
}
#endif
