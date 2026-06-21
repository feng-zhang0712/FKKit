import FKCoreKit
import UIKit
import Foundation

/// ``FKDictionaryMapper`` and ``FKJSONObject`` dynamic access.
final class FKModelMappingExampleDictionaryMappingViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dictionary Mapping"
    addInfoLabel("FKDictionaryMapper.decode without JSON re-serialization.")
    addActionButton("Decode FKMappable user") { [weak self] in
      self?.runMapping("Dictionary decode") {
        let user = try FKDictionaryMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoMappedUser.self, from: FKModelMappingExampleSupport.Payload.nestedDictionary)
        return "Mapped user: \(user.displayName) in \(user.city), tags=\(user.tags)"
      }
    }
    addActionButton("FKModelMapper dictionary API") { [weak self] in
      self?.runMapping("Mapper dictionary") {
        let user = try FKModelMapper.shared
          .decode(FKModelMappingDemoMappedUser.self, from: FKModelMappingExampleSupport.Payload.nestedDictionary)
        return "id=\(user.id), name=\(user.displayName)"
      }
    }
    addActionButton("FKJSONObject path subscript") { [weak self] in
      self?.runMapping("JSONObject") {
        let object = FKJSONObject(FKModelMappingExampleSupport.Payload.nestedDictionary)
        let name = object["profile.display_name"]
        let firstTag = object["tags[0]"]
        return "path name=\(name?.debugDescription ?? "nil"), tag=\(firstTag?.debugDescription ?? "nil")"
      }
    }
    addActionButton("decodeDecodable from dictionary") { [weak self] in
      self?.runMapping("Codable fallback") {
        let dict = try JSONSerialization.jsonObject(with: FKModelMappingExampleSupport.Payload.standardUser) as! [String: Any]
        let user = try FKModelMapper(configuration: .standard).decodeDecodable(FKModelMappingDemoUser.self, from: dict)
        return "decodeDecodable: \(user.displayName)"
      }
    }
  }
}
