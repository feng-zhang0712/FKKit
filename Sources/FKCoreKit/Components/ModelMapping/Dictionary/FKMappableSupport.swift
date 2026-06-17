import Foundation

enum FKMappableSupport {
  static func decode<T>(_ type: T.Type, map: FKMap) throws -> T {
    guard let mappableType = type as? any FKMappable.Type else {
      throw FKMappingError.typeMismatch(
        path: map.collectedWarnings.first?.path ?? "",
        expected: String(describing: type),
        actual: "Non-mappable type"
      )
    }
    return try mappableType.init(map: map) as! T
  }
}
