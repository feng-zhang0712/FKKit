import FKCoreKit
import UIKit
import Foundation

/// snake_case JSON with ``FKModelMappingConfiguration/apiDefault`` and Network decoder injection.
final class FKModelMappingExampleSnakeCaseViewController: FKModelMappingExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Snake Case API"
    addInfoLabel("KeyStrategy.convertFromSnakeCase via .apiDefault with camelCase CodingKeys.")
    addActionButton("Decode snake_case payload") { [weak self] in
      self?.runMapping("Decode snake") {
        let mapper = FKModelMapper(configuration: .apiDefault)
        let user = try mapper.decode(FKModelMappingDemoSnakeUser.self, from: FKModelMappingExampleSupport.Payload.snakeUser)
        return "userId=\(user.userId), name=\(user.displayName), active=\(user.isActive)"
      }
    }
    addActionButton("Inject decoder into FKNetworkClient") { [weak self] in
      self?.runMapping("Network decoder") {
        let codec = FKJSONCodec(configuration: .apiDefault)
        _ = FKNetworkClient(decoder: codec.makeDecoder())
        let user = try codec.decode(FKModelMappingDemoSnakeUser.self, from: FKModelMappingExampleSupport.Payload.snakeUser)
        return "Client decoder OK — \(user.displayName)"
      }
    }
    addActionButton("Compare .standard vs .apiDefault") { [weak self] in
      self?.runMapping("Compare") {
        do {
          _ = try FKModelMapper(configuration: .standard)
            .decode(FKModelMappingDemoSnakeUser.self, from: FKModelMappingExampleSupport.Payload.snakeUser)
          return "Unexpected: strict keys succeeded"
        } catch {
          let user = try FKModelMapper(configuration: .apiDefault)
            .decode(FKModelMappingDemoSnakeUser.self, from: FKModelMappingExampleSupport.Payload.snakeUser)
          return "Strict failed as expected.\napiDefault decoded: \(user.displayName)"
        }
      }
    }
  }
}
