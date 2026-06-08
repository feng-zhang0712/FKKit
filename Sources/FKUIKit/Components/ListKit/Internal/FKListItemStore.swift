import Foundation

/// Side table storing custom cell payloads keyed by item id.
@MainActor
final class FKListItemStore {
  private var payloads: [FKListItemID: FKListItemPayload] = [:]

  func setPayload(_ payload: FKListItemPayload, for id: FKListItemID) {
    payloads[id] = payload
  }

  func payload(for id: FKListItemID) -> FKListItemPayload? {
    payloads[id]
  }

  func prune(keeping ids: Set<FKListItemID>) {
    payloads = payloads.filter { ids.contains($0.key) }
  }
}
