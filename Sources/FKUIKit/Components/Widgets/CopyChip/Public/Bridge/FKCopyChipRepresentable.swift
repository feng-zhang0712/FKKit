#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKCopyChip``.
  public struct FKCopyChipRepresentable: UIViewRepresentable {
    public var configuration: FKCopyChipConfiguration
    public var text: String
    public var copyText: String?
    public var isEnabled: Bool
    public var onCopy: ((String) -> Void)?

    public init(
      configuration: FKCopyChipConfiguration = FKCopyChipDefaults.configuration,
      text: String,
      copyText: String? = nil,
      isEnabled: Bool = true,
      onCopy: ((String) -> Void)? = nil
    ) {
      self.configuration = configuration
      self.text = text
      self.copyText = copyText
      self.isEnabled = isEnabled
      self.onCopy = onCopy
    }

    public func makeUIView(context: Context) -> FKCopyChip {
      let chip = FKCopyChip(configuration: configuration, text: text, copyText: copyText)
      chip.isEnabled = isEnabled
      chip.onCopy = onCopy
      return chip
    }

    public func updateUIView(_ uiView: FKCopyChip, context: Context) {
      uiView.configuration = configuration
      uiView.text = text
      uiView.copyText = copyText
      uiView.isEnabled = isEnabled
      uiView.onCopy = onCopy
    }
  }
#endif
