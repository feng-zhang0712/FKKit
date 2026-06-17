import FKCoreKit
import Foundation

/// Inline JSON fixtures and helpers for FKModelMapping demos.
enum FKModelMappingExampleSupport {
  static func describe(error: Error) -> String {
    if let error = error as? FKMappingError {
      return "FKMappingError: \(error.localizedDescription)"
    }
    if let error = error as? NetworkError {
      return "NetworkError: \(error.localizedDescription)"
    }
    return String(describing: error)
  }

  static func prettyJSON(_ value: some Encodable, mapper: FKModelMapper = FKModelMapper(configuration: .standard)) throws -> String {
    try mapper.encodeString(value)
  }

  static func prettyData(_ data: Data) -> String {
    (String(data: data, encoding: .utf8) ?? "<invalid utf8>")
      .replacingOccurrences(of: "\\/", with: "/")
  }

  enum Payload {
    static let standardUser = Data(
      """
      {"id":1,"displayName":"Ada Lovelace","email":"ada@example.com","isActive":true}
      """.utf8
    )

    static let snakeUser = Data(
      """
      {"user_id":42,"display_name":"Grace Hopper","email_address":"grace@example.com","is_active":true}
      """.utf8
    )

    static let lenientProduct = Data(
      """
      {"sku":"A-1","price":"19.99","quantity":"3","note":"","optionalTag":null}
      """.utf8
    )

    static let strictProduct = Data(
      """
      {"sku":"B-2","price":"not-a-number","quantity":2}
      """.utf8
    )

    static let dateEventISO = Data(
      """
      {"title":"Launch","startsAt":"2026-06-17T10:15:00Z"}
      """.utf8
    )

    static let dateEventSeconds = Data(
      """
      {"title":"Reminder","startsAt":1718616900}
      """.utf8
    )

    static let wrapperPayload = Data(
      """
      {"rating":"4","note":"","tags":["a",42,"broken",{"x":1},"c"]}
      """.utf8
    )

    static let nestedDictionary: [String: Any] = [
      "user_id": "9001",
      "profile": [
        "display_name": "Alan Turing",
        "city": "Manchester",
      ],
      "tags": ["math", "computing"],
    ]

    static let manualMergePayload: [String: Any] = [
      "order_id": "ORD-88",
      "amount_text": "128.50",
      "currency_code": "USD",
      "legacy_total": 999,
    ]

    static let polymorphicFeed: [String: Any] = [
      "items": [
        ["type": "image", "url": "https://cdn.example/photo.jpg"],
        ["type": "text", "body": "Hello FKModelMapping"],
        ["type": "unknown", "value": 1],
      ],
    ]

    static let envelopeSuccess = Data(
      """
      {"code":0,"message":"ok","data":{"id":7,"displayName":"Envelope User","email":"env@example.com","isActive":true}}
      """.utf8
    )

    static let envelopeBusinessFailure = Data(
      """
      {"code":401,"message":"token expired","data":null}
      """.utf8
    )

    static let successFlagEnvelope = Data(
      """
      {"success":true,"result":{"list":[{"id":1,"displayName":"Listed User","email":"list@example.com","isActive":false}],"count":1}}
      """.utf8
    )

    static let pagePayload = Data(
      """
      {"items":[{"id":1,"displayName":"Page One","email":"one@example.com","isActive":true}],"total":42,"page":2,"page_size":10}
      """.utf8
    )

    static let listResponsePayload = Data(
      """
      {"list":[{"id":2,"displayName":"List Two","email":"two@example.com","isActive":false}],"count":1}
      """.utf8
    )
  }
}
