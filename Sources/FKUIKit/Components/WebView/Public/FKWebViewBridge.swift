import Foundation
import WebKit

// MARK: - Bridge registration

/// Registered JavaScript message handler names exposed to the page.
public struct FKJavaScriptBridge: Sendable, Equatable {
  public var handlers: [FKJavaScriptHandlerRegistration]

  public init(handlers: [FKJavaScriptHandlerRegistration] = []) {
    self.handlers = handlers
  }
}

/// Maps a `WKScriptMessageHandler` name to a host-side handler identifier.
public struct FKJavaScriptHandlerRegistration: Sendable, Equatable {
  public var name: String
  public var handlerID: String

  public init(name: String, handlerID: String) {
    self.name = name
    self.handlerID = handlerID
  }
}

/// User script injected at document start or end.
public struct FKUserScriptRegistration: Sendable, Equatable {
  public var source: String
  public var injectionTime: WKUserScriptInjectionTime
  public var forMainFrameOnly: Bool

  public init(
    source: String,
    injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
    forMainFrameOnly: Bool = true
  ) {
    self.source = source
    self.injectionTime = injectionTime
    self.forMainFrameOnly = forMainFrameOnly
  }
}

// MARK: - Message payload

/// JSON-safe message body delivered from JavaScript.
public enum FKJavaScriptMessageBody: Sendable, Equatable {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([FKJavaScriptMessageBody])
  case dictionary([String: FKJavaScriptMessageBody])
}

/// Message received from a registered JavaScript handler.
public struct FKJavaScriptMessage: Sendable, Equatable {
  public var name: String
  public var handlerID: String
  public var body: FKJavaScriptMessageBody

  public init(name: String, handlerID: String, body: FKJavaScriptMessageBody) {
    self.name = name
    self.handlerID = handlerID
    self.body = body
  }
}

enum FKJavaScriptMessageBodyConverter {
  static func convert(_ value: Any?) -> FKJavaScriptMessageBody {
    switch value {
    case nil:
      return .null
    case let bool as Bool:
      return .bool(bool)
    case let int as Int:
      return .int(int)
    case let double as Double:
      return .double(double)
    case let number as NSNumber:
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return .bool(number.boolValue)
      }
      return .double(number.doubleValue)
    case let string as String:
      return .string(string)
    case let array as [Any]:
      return .array(array.map(convert))
    case let dictionary as [String: Any]:
      return .dictionary(dictionary.mapValues(convert))
    default:
      return .string(String(describing: value))
    }
  }
}
