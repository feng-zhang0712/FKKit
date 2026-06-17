import FKCoreKit
import Foundation

// MARK: - Codable models (nonisolated for MainActor example target)

struct FKModelMappingDemoUser: Sendable, Equatable {
  let id: Int
  let displayName: String
  let email: String
  let isActive: Bool
}

extension FKModelMappingDemoUser: Codable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    displayName = try container.decode(String.self, forKey: .displayName)
    email = try container.decode(String.self, forKey: .email)
    isActive = try container.decode(Bool.self, forKey: .isActive)
  }

  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(displayName, forKey: .displayName)
    try container.encode(email, forKey: .email)
    try container.encode(isActive, forKey: .isActive)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case displayName
    case email
    case isActive
  }
}

struct FKModelMappingDemoSnakeUser: Sendable, Equatable {
  let userId: Int
  let displayName: String
  let emailAddress: String
  let isActive: Bool
}

extension FKModelMappingDemoSnakeUser: Codable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userId = try container.decode(Int.self, forKey: .userId)
    displayName = try container.decode(String.self, forKey: .displayName)
    emailAddress = try container.decode(String.self, forKey: .emailAddress)
    isActive = try container.decode(Bool.self, forKey: .isActive)
  }

  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(userId, forKey: .userId)
    try container.encode(displayName, forKey: .displayName)
    try container.encode(emailAddress, forKey: .emailAddress)
    try container.encode(isActive, forKey: .isActive)
  }

  private enum CodingKeys: String, CodingKey {
    case userId
    case displayName
    case emailAddress
    case isActive
  }
}

struct FKModelMappingDemoProduct: Sendable, Equatable {
  let sku: String
  let price: Double
  let quantity: Int
  let note: String?
  let optionalTag: String?
}

struct FKModelMappingDemoLenientProduct: FKMappable, Sendable, Equatable {
  let sku: String
  let price: Double
  let quantity: Int
  let note: String?
  let optionalTag: String?

  init(map: FKMap) throws {
    sku = try map.value("sku", as: String.self)
    price = try map.value("price", as: Double.self)
    quantity = try map.value("quantity", as: Int.self)
    note = map.optionalValue("note", as: String.self)
    optionalTag = map.optionalValue("optionalTag", as: String.self)
  }
}

extension FKModelMappingDemoProduct: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    sku = try container.decode(String.self, forKey: .sku)
    price = try container.decode(Double.self, forKey: .price)
    quantity = try container.decode(Int.self, forKey: .quantity)
    note = try container.decodeIfPresent(String.self, forKey: .note)
    optionalTag = try container.decodeIfPresent(String.self, forKey: .optionalTag)
  }

  private enum CodingKeys: String, CodingKey {
    case sku, price, quantity, note, optionalTag
  }
}

struct FKModelMappingDemoDateEvent: Sendable, Equatable {
  let title: String
  let startsAt: Date
}

extension FKModelMappingDemoDateEvent: Codable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decode(String.self, forKey: .title)
    startsAt = try container.decode(Date.self, forKey: .startsAt)
  }

  private enum CodingKeys: String, CodingKey {
    case title, startsAt
  }
}

struct FKModelMappingDemoWrapperModel: Sendable, Equatable {
  let rating: Int
  let note: String?
  let tags: [String]
}

extension FKModelMappingDemoWrapperModel: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let intRating = try? container.decode(Int.self, forKey: .rating) {
      rating = intRating
    } else if let stringRating = try? container.decode(String.self, forKey: .rating),
              let parsed = Int(stringRating) {
      rating = parsed
    } else {
      rating = try container.decode(FKDefault.self, forKey: .rating, default: 0).wrappedValue
    }

    if let noteValue = try container.decodeIfPresent(String.self, forKey: .note), !noteValue.fk_isBlank {
      note = noteValue
    } else {
      note = nil
    }

    tags = try container.decode(FKLossyArray<String>.self, forKey: .tags).wrappedValue
  }

  private enum CodingKeys: String, CodingKey {
    case rating, note, tags
  }
}

struct FKModelMappingDemoCreateUserRequest: Sendable, Encodable {
  let displayName: String
  let emailAddress: String
  let isActive: Bool
}

extension FKModelMappingDemoCreateUserRequest {
  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(displayName, forKey: .displayName)
    try container.encode(emailAddress, forKey: .emailAddress)
    try container.encode(isActive, forKey: .isActive)
  }

  private enum CodingKeys: String, CodingKey {
    case displayName = "display_name"
    case emailAddress = "email_address"
    case isActive = "is_active"
  }
}

// MARK: - Dictionary / FKMappable models

struct FKModelMappingDemoMappedUser: FKMappable, Sendable, Equatable {
  let id: Int
  let displayName: String
  let city: String
  let tags: [String]

  init(map: FKMap) throws {
    id = try map.value("user_id", as: Int.self)
    displayName = try map.value("profile.display_name", as: String.self)
    city = try map.value("profile.city", as: String.self)
    tags = [
      map.optionalValue("tags[0]", as: String.self),
      map.optionalValue("tags[1]", as: String.self),
    ].compactMap { $0 }
  }
}

struct FKModelMappingDemoManualOrder: FKMappable, Sendable, Equatable {
  let orderID: String
  let amount: Double
  let currency: String

  init(map: FKMap) throws {
    orderID = try map.value("order_id", as: String.self)
    currency = map.value("currency_code", as: String.self, default: "USD")

    if let amountText = map.optionalValue("amount_text", as: String.self),
       let parsed = Double(amountText) {
      amount = parsed
    } else if let legacy = map.optionalValue("legacy_total", as: Double.self) {
      amount = legacy
    } else {
      amount = try map.value("amount_text", as: Double.self)
    }
  }
}

enum FKModelMappingDemoFeedItem: FKPolymorphicDecodable, Sendable, Equatable {
  case image(url: String)
  case text(body: String)

  static let discriminatorKey = "type"

  static func decode(from map: FKMap, typeValue: String) throws -> FKModelMappingDemoFeedItem {
    switch typeValue {
    case "image":
      return .image(url: try map.value("url", as: String.self))
    case "text":
      return .text(body: try map.value("body", as: String.self))
    default:
      throw FKMappingError.typeMismatch(path: discriminatorKey, expected: "image|text", actual: typeValue)
    }
  }
}

struct FKModelMappingDemoFeed: FKMappable, Sendable, Equatable {
  let items: [FKModelMappingDemoFeedItem]

  init(map: FKMap) throws {
    items = try map.polymorphicArray("items", as: FKModelMappingDemoFeedItem.self)
  }
}

// MARK: - Network mock request

struct FKModelMappingDemoEnvelopeUserRequest: Requestable {
  typealias Response = FKModelMappingDemoUser

  var path: String { "/demo/envelope-user" }
  var method: HTTPMethod { .get }
  var mockData: Data? { FKModelMappingExampleSupport.Payload.envelopeSuccess }
}
