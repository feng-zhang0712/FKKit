/// FKPluggable — protocol contracts for pluggable iOS app infrastructure.
///
/// This module defines **narrow, swappable boundaries** (networking, analytics, storage,
/// session, configuration, localization, routing, logging, images, and list cells).
/// Implementations live in the host application or other FKCoreKit areas; this folder
/// ships **protocols and shared value types only** (no third-party dependencies).
///
/// ## Design principles
/// - **Protocol-oriented**: depend on abstractions at module boundaries.
/// - **Injectable**: wire concrete types at app launch or in tests.
/// - **Testable**: conform with mocks/stubs without subclassing UIKit.
/// - **Sendable-first**: value types and `Sendable` constraints where practical (Swift 6).
///
/// ## Location
/// Sources live under `Sources/FKCoreKit/Pluggable/`. Import **`FKCoreKit`** from SPM or CocoaPods.
public enum FKPluggable {
  /// Current contract revision (semver-aligned with FKKit releases).
  public static let contractVersion = 1
}
