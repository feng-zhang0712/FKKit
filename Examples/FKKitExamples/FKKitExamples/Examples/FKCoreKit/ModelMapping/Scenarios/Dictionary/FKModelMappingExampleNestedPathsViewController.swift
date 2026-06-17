import FKCoreKit
import UIKit
import Foundation

/// Nested path keys via ``FKMap`` and ``FKMappable``.
final class FKModelMappingExampleNestedPathsViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Nested Paths"
    addInfoLabel("profile.display_name and array paths resolved by FKJSONPathResolver.")
    addActionButton("Map nested profile fields") { [weak self] in
      self?.runMapping("Nested paths") {
        let user = try FKDictionaryMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoMappedUser.self, from: FKModelMappingExampleSupport.Payload.nestedDictionary)
        return """
        id=\(user.id)
        displayName=\(user.displayName)
        city=\(user.city)
        tags=\(user.tags.joined(separator: ", "))
        """
      }
    }
    addActionButton("FKMap.nestedObject") { [weak self] in
      self?.runMapping("Nested object") {
        let map = FKMap.root(FKModelMappingExampleSupport.Payload.nestedDictionary, configuration: .lenientAPI)
        let profile = map.nestedObject("profile")
        let city = profile?.optionalValue("city", as: String.self) ?? "unknown"
        return "nested profile city=\(city)"
      }
    }
    addActionButton("Path resolver array index") { [weak self] in
      self?.runMapping("Array index") {
        let object = FKJSONObject(FKModelMappingExampleSupport.Payload.nestedDictionary)
        return "tags[1]=\(object["tags[1]"]?.debugDescription ?? "nil")"
      }
    }
  }
}
