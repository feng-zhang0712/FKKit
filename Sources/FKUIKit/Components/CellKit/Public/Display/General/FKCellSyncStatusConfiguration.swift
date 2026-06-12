import Foundation

/// Sync state for ``FKCellSyncStatusCell`` (D-36).
public enum FKCellSyncState: Sendable, Equatable {
  case idle
  case syncing
  case success
  case failure
}

/// Configuration for ``FKCellSyncStatusCell`` (D-36).
public struct FKCellSyncStatusConfiguration: Sendable, Equatable {
  public var title: String
  public var statusText: String?
  public var syncState: FKCellSyncState
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    title: String,
    statusText: String? = nil,
    syncState: FKCellSyncState = .idle,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.statusText = statusText
    self.syncState = syncState
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
