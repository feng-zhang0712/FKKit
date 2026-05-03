#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKProgressBar`` / ``FKProgressBarConfiguration``.
public struct FKProgressBarView: UIViewRepresentable {
  @Binding public var progress: CGFloat
  @Binding public var bufferProgress: CGFloat
  @Binding public var isIndeterminate: Bool
  public var configuration: FKProgressBarConfiguration
  public var animateChanges: Bool

  public init(
    progress: Binding<CGFloat>,
    bufferProgress: Binding<CGFloat> = .constant(0),
    isIndeterminate: Binding<Bool> = .constant(false),
    configuration: FKProgressBarConfiguration = FKProgressBarDefaults.configuration,
    animateChanges: Bool = true
  ) {
    _progress = progress
    _bufferProgress = bufferProgress
    _isIndeterminate = isIndeterminate
    self.configuration = configuration
    self.animateChanges = animateChanges
  }

  public func makeUIView(context: Context) -> FKProgressBar {
    let v = FKProgressBar(configuration: configuration)
    v.setProgress(progress, buffer: bufferProgress, animated: false)
    v.isIndeterminate = isIndeterminate
    return v
  }

  public func updateUIView(_ uiView: FKProgressBar, context: Context) {
    uiView.configuration = configuration
    uiView.isIndeterminate = isIndeterminate
    uiView.setProgress(progress, buffer: bufferProgress, animated: animateChanges)
  }
}
#endif
