import Foundation

/// Manual mapping context backed by a read-only dictionary snapshot.
public struct FKMap: @unchecked Sendable {
  private let root: [String: Any]
  private let configuration: FKModelMappingConfiguration
  private let transformRegistry: FKTransformRegistry
  private let pathPrefix: String
  private let warningCollector: FKMappingWarningCollector

  init(
    root: [String: Any],
    configuration: FKModelMappingConfiguration,
    transformRegistry: FKTransformRegistry,
    pathPrefix: String = "",
    warningCollector: FKMappingWarningCollector = FKMappingWarningCollector()
  ) {
    self.root = root
    self.configuration = configuration
    self.transformRegistry = transformRegistry
    self.pathPrefix = pathPrefix
    self.warningCollector = warningCollector
  }

  /// Creates a root mapping context for a dynamic dictionary payload.
  public static func root(
    _ dictionary: [String: Any],
    configuration: FKModelMappingConfiguration = .lenientAPI,
    transformRegistry: FKTransformRegistry = .default
  ) -> FKMap {
    FKMap(root: dictionary, configuration: configuration, transformRegistry: transformRegistry)
  }

  /// Collected non-fatal warnings in lenient mode.
  public var collectedWarnings: [FKMappingWarning] {
    warningCollector.all
  }

  /// Returns a nested map when the value at `key` is a dictionary or path resolves to one.
  public func nestedObject(_ key: String) -> FKMap? {
    let paths = paths(for: key)
    guard let value = FKJSONPathResolver.resolve(path: paths.resolution, in: root) else { return nil }
    if let dictionary = value as? [String: Any] {
      return FKMap(
        root: dictionary,
        configuration: configuration,
        transformRegistry: transformRegistry,
        pathPrefix: paths.reporting,
        warningCollector: warningCollector
      )
    }
    return nil
  }

  /// Reads a required value at `key` or path.
  public func value<T>(_ key: String, as type: T.Type = T.self) throws -> T {
    let paths = paths(for: key)
    guard let rawValue = normalizedValue(at: paths.resolution) else {
      throw FKMappingError.keyNotFound(path: paths.reporting)
    }
    return try cast(rawValue, to: type, path: paths.reporting)
  }

  /// Reads a value with a default fallback.
  public func value<T>(_ key: String, as type: T.Type = T.self, default defaultValue: T) -> T {
    (try? value(key, as: type)) ?? defaultValue
  }

  /// Reads an optional value at `key` or path.
  public func optionalValue<T>(_ key: String, as type: T.Type = T.self) -> T? {
    try? value(key, as: type)
  }

  /// Reads and maps an array of ``FKMappable`` elements.
  public func array<T>(_ key: String, as element: T.Type) throws -> [T] where T: FKMappable {
    let paths = paths(for: key)
    guard let rawValue = FKJSONPathResolver.resolve(path: paths.resolution, in: root) else {
      throw FKMappingError.keyNotFound(path: paths.reporting)
    }
    guard let array = rawValue as? [Any] else {
      throw FKMappingError.typeMismatch(
        path: paths.reporting,
        expected: "Array",
        actual: String(describing: Swift.type(of: rawValue))
      )
    }

    var result: [T] = []
    for (index, item) in array.enumerated() {
      let itemPath = "\(paths.reporting)[\(index)]"
      do {
        let dictionary = try requireDictionary(item, path: itemPath)
        let childMap = FKMap(
          root: dictionary,
          configuration: configuration,
          transformRegistry: transformRegistry,
          pathPrefix: itemPath,
          warningCollector: warningCollector
        )
        result.append(try T(map: childMap))
      } catch {
        if configuration.mappingMode == .lenient {
          warningCollector.append(FKMappingWarning(path: itemPath, message: error.localizedDescription))
          continue
        }
        throw error
      }
    }
    return result
  }

  /// Reads a polymorphic array using ``FKPolymorphicDecodable``.
  public func polymorphicArray<T>(_ key: String, as type: T.Type = T.self) throws -> [T] where T: FKPolymorphicDecodable {
    let paths = paths(for: key)
    guard let rawValue = FKJSONPathResolver.resolve(path: paths.resolution, in: root) else {
      throw FKMappingError.keyNotFound(path: paths.reporting)
    }
    guard let array = rawValue as? [Any] else {
      throw FKMappingError.typeMismatch(
        path: paths.reporting,
        expected: "Array",
        actual: String(describing: Swift.type(of: rawValue))
      )
    }

    var result: [T] = []
    for (index, item) in array.enumerated() {
      let itemPath = "\(paths.reporting)[\(index)]"
      let dictionary = try requireDictionary(item, path: itemPath)
      let childMap = FKMap(
        root: dictionary,
        configuration: configuration,
        transformRegistry: transformRegistry,
        pathPrefix: itemPath,
        warningCollector: warningCollector
      )
      do {
        guard let typeValue = FKValueParsing.string(from: dictionary[T.discriminatorKey]) else {
          throw FKMappingError.keyNotFound(path: "\(itemPath).\(T.discriminatorKey)")
        }
        result.append(try T.decode(from: childMap, typeValue: typeValue))
      } catch {
        if configuration.mappingMode == .lenient {
          warningCollector.append(FKMappingWarning(path: itemPath, message: error.localizedDescription))
          continue
        }
        throw error
      }
    }
    return result
  }

  private func paths(for key: String) -> (resolution: String, reporting: String) {
    let reporting = joinedPath(key)
    let resolution: String
    if !pathPrefix.isEmpty, !key.contains("."), !key.contains("[") {
      resolution = key
    } else {
      resolution = joinedPath(key)
    }
    return (resolution, reporting)
  }

  private func joinedPath(_ key: String) -> String {
    if pathPrefix.isEmpty { return key }
    if key.contains(".") || key.contains("[") { return key }
    return "\(pathPrefix).\(key)"
  }

  private func normalizedValue(at path: String) -> Any? {
    guard let value = FKJSONPathResolver.resolve(path: path, in: root) else { return nil }
    if value is NSNull { return nil }

    if configuration.nilValueStrategy.contains(.treatEmptyStringAsNil),
       let string = value as? String,
       string.fk_isBlank {
      return nil
    }

    if configuration.nilValueStrategy.contains(.treatNSNumberZeroAsNil),
       let number = value as? NSNumber,
       number.doubleValue == 0 {
      return nil
    }

    return value
  }

  private func requireDictionary(_ value: Any, path: String) throws -> [String: Any] {
    guard let dictionary = value as? [String: Any] else {
      throw FKMappingError.typeMismatch(path: path, expected: "Dictionary", actual: String(describing: Swift.type(of: value)))
    }
    return dictionary
  }

  private func cast<T>(_ value: Any, to type: T.Type, path: String) throws -> T {
    if let typed = value as? T {
      return typed
    }

    if T.self == Int.self {
      if configuration.lenientNumberParsing, let int = FKValueParsing.int(from: value) {
        return int as! T
      }
    }

    if T.self == Double.self {
      if configuration.lenientNumberParsing, let double = FKValueParsing.double(from: value) {
        return double as! T
      }
    }

    if T.self == String.self {
      if let string = FKValueParsing.string(from: value) {
        return string as! T
      }
    }

    if T.self == Bool.self {
      if let bool = try decodeBool(from: value) {
        return bool as! T
      }
    }

    if T.self == URL.self {
      let transform = FKURLTransform()
      if let url = try transform.transformFromJSON(value) {
        return url as! T
      }
    }

    if T.self == Date.self {
      if let date = try FKDateTransformSupport.decode(value, strategy: configuration.dateDecoding) {
        return date as! T
      }
    }

    if T.self == Data.self {
      let transform = FKDataTransform()
      if let data = try transform.transformFromJSON(value) {
        return data as! T
      }
    }

    if let transform = transformRegistry.transform(for: type),
       let transformed = try transform.transformFromJSON(value) as? T {
      return transformed
    }

    if let dictionary = value as? [String: Any], T.self is any FKMappable.Type {
      let childMap = FKMap(
        root: dictionary,
        configuration: configuration,
        transformRegistry: transformRegistry,
        pathPrefix: path,
        warningCollector: warningCollector
      )
      return try FKMappableSupport.decode(T.self, map: childMap)
    }

    if configuration.mappingMode == .lenient {
      warningCollector.append(
        FKMappingWarning(
          path: path,
          message: "Unable to cast \(String(describing: Swift.type(of: value))) to \(String(describing: T.self))."
        )
      )
      throw FKMappingError.typeMismatch(
        path: path,
        expected: String(describing: T.self),
        actual: String(describing: Swift.type(of: value))
      )
    }

    throw FKMappingError.typeMismatch(
      path: path,
      expected: String(describing: T.self),
      actual: String(describing: Swift.type(of: value))
    )
  }

  private func decodeBool(from value: Any) throws -> Bool? {
    switch configuration.boolDecoding {
    case .jsonBool:
      if let bool = value as? Bool {
        return bool
      }
      if let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() {
        return number.boolValue
      }
      return nil
    case .numericOrString:
      return try FKBoolTransform().transformFromJSON(value)
    }
  }
}
