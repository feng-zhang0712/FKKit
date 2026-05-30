#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Holds a weak UIKit anchor surfaced from SwiftUI without storing `UIView` in `@State`.
@MainActor
public final class FKCalloutSwiftUIAnchorBox: ObservableObject {
  /// Latest anchor view from ``FKCalloutSwiftUIAnchorButton``.
  public weak var view: UIView?

  public init() {}
}

/// Surfaces a UIKit button anchor to SwiftUI for ``FKTooltip`` / ``FKPopover`` presentation.
public struct FKCalloutSwiftUIAnchorButton: UIViewRepresentable {
  private let title: String
  private let anchorBox: FKCalloutSwiftUIAnchorBox

  /// Creates an anchor button that publishes its `UIView` to ``anchorBox``.
  public init(title: String, anchorBox: FKCalloutSwiftUIAnchorBox) {
    self.title = title
    self.anchorBox = anchorBox
  }

  public func makeUIView(context: Context) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.baseBackgroundColor = UIColor.systemIndigo
    config.baseForegroundColor = .white
    config.cornerStyle = .medium
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return button
  }

  public func updateUIView(_ uiView: UIButton, context: Context) {
    context.coordinator.anchorBox.view = uiView
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(anchorBox: anchorBox)
  }

  /// Retains the anchor box for the representable lifetime.
  public final class Coordinator {
    let anchorBox: FKCalloutSwiftUIAnchorBox

    init(anchorBox: FKCalloutSwiftUIAnchorBox) {
      self.anchorBox = anchorBox
    }
  }
}
#endif
