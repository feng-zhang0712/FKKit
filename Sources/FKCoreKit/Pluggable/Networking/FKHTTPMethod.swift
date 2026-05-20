import Foundation

/// HTTP methods supported by ``FKAPIRequest`` and ``FKAPIClientProviding``.
public enum FKHTTPMethod: String, Sendable, Hashable, CaseIterable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
  case head = "HEAD"
}
