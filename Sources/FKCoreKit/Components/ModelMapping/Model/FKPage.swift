import Foundation

/// Generic paginated list payload template.
public struct FKPage<Item: Decodable & Sendable>: Decodable, Sendable {
  /// Page items.
  public let items: [Item]
  /// Total item count reported by the server.
  public let total: Int
  /// Current page index when provided by the backend.
  public let page: Int?
  /// Page size when provided by the backend.
  public let pageSize: Int?

  enum CodingKeys: String, CodingKey {
    case items
    case total
    case page
    case pageSize = "page_size"
  }

  /// Creates a page value.
  public init(items: [Item], total: Int, page: Int? = nil, pageSize: Int? = nil) {
    self.items = items
    self.total = total
    self.page = page
    self.pageSize = pageSize
  }
}

/// Alternate list response shape using `list` + `count` keys.
public struct FKListResponse<Item: Decodable & Sendable>: Decodable, Sendable {
  /// List items.
  public let list: [Item]
  /// Total count.
  public let count: Int

  /// Creates a list response value.
  public init(list: [Item], count: Int) {
    self.list = list
    self.count = count
  }
}
