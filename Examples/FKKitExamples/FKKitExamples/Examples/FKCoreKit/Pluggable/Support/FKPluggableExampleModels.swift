import Foundation
import FKCoreKit

/// Sample payload for storage demos (manual JSON to avoid MainActor-isolated `Codable` in the Examples target).
struct DemoStoredProfile: Sendable, Equatable {
  var name: String
  var tier: String

  nonisolated func encodedData() throws -> Data {
    try JSONSerialization.data(withJSONObject: ["name": name, "tier": tier])
  }

  nonisolated static func decoded(from data: Data) throws -> DemoStoredProfile {
    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
      let name = json["name"],
      let tier = json["tier"]
    else {
      throw URLError(.cannotParseResponse)
    }
    return DemoStoredProfile(name: name, tier: tier)
  }
}
