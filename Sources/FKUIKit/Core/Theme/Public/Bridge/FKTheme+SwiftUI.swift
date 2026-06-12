#if canImport(SwiftUI)
import SwiftUI

private struct FKThemeEnvironmentKey: EnvironmentKey {
  static let defaultValue: FKTheme = .default
}

public extension EnvironmentValues {
  /// Read-only FK theme snapshot for SwiftUI subtrees.
  var fkTheme: FKTheme {
    get { self[FKThemeEnvironmentKey.self] }
    set { self[FKThemeEnvironmentKey.self] = newValue }
  }
}

public extension View {
  /// Injects a FK theme snapshot without mutating ``FKThemeRegistry``.
  func fkTheme(_ theme: FKTheme) -> some View {
    environment(\.fkTheme, theme)
  }
}
#endif
