#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper for ``FKSearchField`` with two-way text binding and loading state.
@available(iOS 15.0, *)
public struct FKSearchFieldRepresentable: UIViewRepresentable {
  @Binding public var text: String
  public var configuration: FKSearchFieldConfiguration
  public var placeholder: String?
  public var isLoading: Bool
  public var onSearchQueryChanged: ((String) -> Void)?
  public var onSubmit: ((String) -> Void)?

  public init(
    text: Binding<String>,
    configuration: FKSearchFieldConfiguration = FKSearchFieldDefaults.defaultConfiguration,
    placeholder: String? = nil,
    isLoading: Bool = false,
    onSearchQueryChanged: ((String) -> Void)? = nil,
    onSubmit: ((String) -> Void)? = nil
  ) {
    _text = text
    self.configuration = configuration
    self.placeholder = placeholder
    self.isLoading = isLoading
    self.onSearchQueryChanged = onSearchQueryChanged
    self.onSubmit = onSubmit
  }

  @MainActor
  public final class Coordinator {
    var textBinding: Binding<String>
    var onSearchQueryChanged: ((String) -> Void)?
    var onSubmit: ((String) -> Void)?

    init(
      textBinding: Binding<String>,
      onSearchQueryChanged: ((String) -> Void)?,
      onSubmit: ((String) -> Void)?
    ) {
      self.textBinding = textBinding
      self.onSearchQueryChanged = onSearchQueryChanged
      self.onSubmit = onSubmit
    }

    func wireCallbacks(on field: FKSearchField) {
      field.callbacks.onTextChanged = { [weak self] value in
        guard let self else { return }
        if self.textBinding.wrappedValue != value {
          self.textBinding.wrappedValue = value
        }
      }
      field.callbacks.onSearchQueryChanged = { [weak self] query in
        self?.onSearchQueryChanged?(query)
      }
      field.callbacks.onSubmit = { [weak self] query in
        self?.onSubmit?(query)
      }
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(
      textBinding: _text,
      onSearchQueryChanged: onSearchQueryChanged,
      onSubmit: onSubmit
    )
  }

  public func makeUIView(context: Context) -> FKSearchField {
    let field = FKSearchField(configuration: configuration, placeholder: placeholder)
    field.setText(text, options: .silent)
    context.coordinator.wireCallbacks(on: field)
    field.setLoading(isLoading, animated: false)
    return field
  }

  public func updateUIView(_ uiView: FKSearchField, context: Context) {
    context.coordinator.textBinding = _text
    context.coordinator.onSearchQueryChanged = onSearchQueryChanged
    context.coordinator.onSubmit = onSubmit
    context.coordinator.wireCallbacks(on: uiView)

    uiView.apply(configuration)
    if uiView.placeholder != placeholder {
      uiView.placeholder = placeholder
    }
    if uiView.text != text {
      uiView.setText(text, options: .silent)
    }
    uiView.setLoading(isLoading, animated: true)
  }
}
#endif
