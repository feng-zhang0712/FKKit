import FKCoreKit
import UIKit

/// Debounce scheduling and query normalization for search controls.
@MainActor
final class FKSearchInputCoordinator {
  struct Configuration {
    var debounce: FKSearchDebounceConfiguration
    var textInput: FKSearchTextInputTraitsConfiguration
  }

  var configuration: Configuration {
    didSet { rebuildDebouncerIfNeeded() }
  }

  private var debouncer: FKDebouncer

  init(configuration: Configuration) {
    self.configuration = configuration
    debouncer = FKDebouncer(interval: configuration.debounce.debounceInterval)
  }

  func cancelPending() {
    debouncer.cancelPending()
  }

  func scheduleSearchQuery(
    rawText: String,
    emit: @escaping @MainActor (String) -> Void
  ) {
    let normalized = normalizedQuery(from: rawText)
    guard shouldEmitSearchQuery(normalized) else { return }

    if configuration.debounce.isDebounceEnabled {
      let query = normalized
      debouncer.signal {
        Task { @MainActor in
          emit(query)
        }
      }
    } else {
      emit(normalized)
    }
  }

  func flushSearchQuery(
    rawText: String,
    emit: @escaping @MainActor (String) -> Void
  ) {
    debouncer.cancelPending()
    let normalized = normalizedQuery(from: rawText)
    guard shouldEmitSearchQuery(normalized) else { return }
    emit(normalized)
  }

  func normalizedQuery(from rawText: String) -> String {
    FKSearchTextNormalizationApplier.apply(configuration.textInput.normalization, to: rawText)
  }

  private func shouldEmitSearchQuery(_ normalized: String) -> Bool {
    normalized.count >= configuration.debounce.minimumQueryLengthForSearchCallback
  }

  private func rebuildDebouncerIfNeeded() {
    debouncer.cancelPending()
    debouncer = FKDebouncer(interval: configuration.debounce.debounceInterval)
  }

  deinit {
    debouncer.cancelPending()
  }
}
