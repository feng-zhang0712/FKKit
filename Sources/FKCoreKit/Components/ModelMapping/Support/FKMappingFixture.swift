import Foundation

/// Loads bundled JSON fixtures for mapping demos and tests.
public enum FKMappingFixture {
  /// Loads JSON data from a bundle resource.
  public static func data(named name: String, bundle: Bundle = .main) throws -> Data {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw FKMappingError.keyNotFound(path: name)
    }
    return try Data(contentsOf: url)
  }

  /// Loads a JSON dictionary from a bundle resource.
  public static func dictionary(named name: String, bundle: Bundle = .main) throws -> [String: Any] {
    let data = try data(named: name, bundle: bundle)
    let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    guard let dictionary = object as? [String: Any] else {
      throw FKMappingError.invalidJSON(underlying: nil)
    }
    return dictionary
  }
}
