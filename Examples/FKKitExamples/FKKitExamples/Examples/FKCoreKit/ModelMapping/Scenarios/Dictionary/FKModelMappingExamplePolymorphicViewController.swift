import FKCoreKit
import UIKit
import Foundation

/// Discriminator-based polymorphic arrays.
final class FKModelMappingExamplePolymorphicViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Polymorphic Feed"
    addInfoLabel("FKPolymorphicDecodable + FKMap.polymorphicArray with type discriminator.")
    addActionButton("Decode polymorphic feed") { [weak self] in
      self?.runMapping("Polymorphic") {
        let feed = try FKDictionaryMapper(configuration: .lenientAPI)
          .decode(FKModelMappingDemoFeed.self, from: FKModelMappingExampleSupport.Payload.polymorphicFeed)
        let summary = feed.items.map { item -> String in
          switch item {
          case let .image(url): return "image(\(url))"
          case let .text(body): return "text(\(body))"
          }
        }.joined(separator: "\n")
        return "items:\n\(summary)"
      }
    }
    addActionButton("Strict fails on unknown type") { [weak self] in
      self?.runMapping("Strict polymorphic") {
        do {
          _ = try FKDictionaryMapper(configuration: .strict)
            .decode(FKModelMappingDemoFeed.self, from: FKModelMappingExampleSupport.Payload.polymorphicFeed)
          return "Unexpected success"
        } catch {
          return FKModelMappingExampleSupport.describe(error: error)
        }
      }
    }
    addActionButton("FKPolymorphicRegistry") { [weak self] in
      self?.runMapping("Registry") {
        let registry = FKPolymorphicRegistry()
          .registering("image") { map in try FKModelMappingDemoFeedItem.image(url: map.value("url", as: String.self)) }
          .registering("text") { map in try FKModelMappingDemoFeedItem.text(body: map.value("body", as: String.self)) }
        let itemJSON: [String: Any] = ["type": "text", "body": "Registry item"]
        let map = FKMap.root(itemJSON, configuration: .lenientAPI)
        let item = try registry.decode(from: map, typeValue: "text", as: FKModelMappingDemoFeedItem.self)
        if case let .text(body) = item { return "Registry decoded: \(body)" }
        return "Unexpected item"
      }
    }
  }
}
