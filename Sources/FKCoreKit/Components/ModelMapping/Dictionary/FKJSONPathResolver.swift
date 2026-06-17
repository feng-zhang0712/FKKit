import Foundation

enum FKJSONPathResolver {
  enum Segment: Equatable {
    case key(String)
    case index(Int)
  }

  static func parse(path: String) throws -> [Segment] {
    guard !path.isEmpty else {
      throw FKMappingError.invalidPath(path: path, reason: "Path is empty.")
    }

    var segments: [Segment] = []
    var currentKey = ""

    func flushKey() {
      guard !currentKey.isEmpty else { return }
      segments.append(.key(currentKey))
      currentKey = ""
    }

    var index = path.startIndex
    while index < path.endIndex {
      let character = path[index]
      if character == "." {
        flushKey()
        index = path.index(after: index)
        continue
      }

      if character == "[" {
        flushKey()
        guard let closing = path[index...].firstIndex(of: "]") else {
          throw FKMappingError.invalidPath(path: path, reason: "Missing closing bracket.")
        }
        let rawIndex = path[path.index(after: index) ..< closing]
        guard let arrayIndex = Int(rawIndex) else {
          throw FKMappingError.invalidPath(path: path, reason: "Invalid array index.")
        }
        segments.append(.index(arrayIndex))
        index = path.index(after: closing)
        continue
      }

      currentKey.append(character)
      index = path.index(after: index)
    }

    flushKey()
    return segments
  }

  static func resolve(path: String, in root: Any?) -> Any? {
    guard let segments = try? parse(path: path) else { return nil }
    return resolve(segments: segments, in: root)
  }

  static func resolve(segments: [Segment], in root: Any?) -> Any? {
    var current: Any? = root
    for segment in segments {
      switch segment {
      case let .key(key):
        guard let dictionary = current as? [String: Any] else { return nil }
        current = dictionary[key]
      case let .index(index):
        guard let array = current as? [Any], array.indices.contains(index) else { return nil }
        current = array[index]
      }
    }
    return current
  }
}

enum FKJSONParser {
  static func parseJSONObject(
    from data: Data,
    maxDepth: Int,
    maxArrayCount: Int
  ) throws -> Any {
    let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    try validate(object: object, depth: 0, maxDepth: maxDepth, maxArrayCount: maxArrayCount)
    return object
  }

  static func parseJSONObject(
    from dictionary: [String: Any],
    maxDepth: Int,
    maxArrayCount: Int
  ) throws -> Any {
    try validate(object: dictionary, depth: 0, maxDepth: maxDepth, maxArrayCount: maxArrayCount)
    return dictionary
  }

  private static func validate(object: Any, depth: Int, maxDepth: Int, maxArrayCount: Int) throws {
    guard depth <= maxDepth else {
      throw FKMappingError.payloadLimitExceeded(reason: "Maximum nesting depth exceeded.")
    }

    if let array = object as? [Any] {
      guard array.count <= maxArrayCount else {
        throw FKMappingError.payloadLimitExceeded(reason: "Maximum array count exceeded.")
      }
      for element in array {
        try validate(object: element, depth: depth + 1, maxDepth: maxDepth, maxArrayCount: maxArrayCount)
      }
      return
    }

    if let dictionary = object as? [String: Any] {
      for value in dictionary.values {
        try validate(object: value, depth: depth + 1, maxDepth: maxDepth, maxArrayCount: maxArrayCount)
      }
    }
  }
}
