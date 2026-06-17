import FKCoreKit
import UIKit
import Foundation

/// End-to-end mapping of a deeply nested, loosely typed workspace hub API payload.
final class FKModelMappingExampleComplexPayloadViewController: FKModelMappingExampleBaseViewController {
  private let configuration = FKModelMappingExampleComplexPayloadSupport.mappingConfiguration

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Complex Payload"
    addInfoLabel(
      """
      Fixture: fixture_complex_workspace_hub.json
      Envelope + nested paths + polymorphic blocks + embedded JSON strings + mixed scalars/dates/nulls.
      """
    )

    addActionButton("1. Inspect fixture structure") { [weak self] in
      self?.runMapping("Fixture structure") {
        let data = try FKModelMappingExampleComplexPayloadSupport.loadFixture()
        return try FKModelMappingExampleComplexPayloadSupport.fixtureSummary(from: data)
      }
    }

    addActionButton("2. Unwrap envelope + decode hub") { [weak self] in
      self?.runMapping("Envelope + hub") {
        guard let self else { return "Unavailable" }
        let hub = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture())
        return """
        request=\(hub.meta.requestID)
        workspace=\(hub.workspace.displayName)
        blocks=\(hub.feedPage.blocks.count)/\(hub.feedPage.total)
        next=\(hub.links.next?.absoluteString ?? "-")
        """
      }
    }

    addActionButton("3. Workspace owner + embedded JSON") { [weak self] in
      self?.runMapping("Workspace") {
        guard let self else { return "Unavailable" }
        let workspace = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture()).workspace
        let settings = workspace.settings
        return """
        owner=\(workspace.owner.displayName) (id=\(workspace.owner.userID))
        channels=\(workspace.owner.channels.joined(separator: ", "))
        theme=\(settings?.theme ?? "-") labs=\(settings?.labs.joined(separator: ",") ?? "-")
        layoutRegions=\(workspace.layoutRegions.count)
        active=\(workspace.isActive)
        """
      }
    }

    addActionButton("4. Polymorphic feed blocks (lenient)") { [weak self] in
      self?.runMapping("Polymorphic blocks") {
        guard let self else { return "Unavailable" }
        let blocks = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture()).feedPage.blocks
        let summary = blocks.map(\.kindLabel).joined(separator: ", ")
        return "decoded \(blocks.count) blocks (unknown skipped): \(summary)"
      }
    }

    addActionButton("5. Articles, KPI metrics, mixed dates") { [weak self] in
      self?.runMapping("Nested content") {
        guard let self else { return "Unavailable" }
        let blocks = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture()).feedPage.blocks
        var lines: [String] = []
        for block in blocks {
          switch block {
          case let .articleList(list):
            let first = list.articles.first
            lines.append("articles=\(list.articles.count), first=\(first?.headline ?? "-")")
          case let .kpiWidget(widget):
            lines.append("metrics=\(widget.metrics.count), first=\(widget.metrics.first?.label ?? "-")")
          default:
            continue
          }
        }
        return lines.joined(separator: "\n")
      }
    }

    addActionButton("6. Facets + sort props + warnings path") { [weak self] in
      self?.runMapping("Facets") {
        guard let self else { return "Unavailable" }
        let hub = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture())
        let sort = hub.feedPage.sortProps.map { "\($0.key)=\($0.ascending)" }.joined(separator: ", ")
        let counts = hub.facets.enabledCounts.map { "\($0.key):\($0.value)" }.joined(separator: ", ")
        return """
        blockTypes=\(hub.facets.blockTypes.joined(separator: ", "))
        enabledCounts=\(counts)
        sortProps=\(sort)
        """
      }
    }

    addActionButton("7. Full pipeline summary") { [weak self] in
      self?.runMapping("Full pipeline") {
        guard let self else { return "Unavailable" }
        let hub = try self.decodeHub(from: FKModelMappingExampleComplexPayloadSupport.loadFixture())
        let blockLines = hub.feedPage.blocks.map { block -> String in
          switch block {
          case let .heroBanner(hero):
            return "  • \(hero.title) [\(block.kindLabel)] priority=\(hero.priority)"
          case let .articleList(list):
            return "  • \(list.title) [\(block.kindLabel)] articles=\(list.articles.count)"
          case let .kpiWidget(widget):
            return "  • \(widget.title) [\(block.kindLabel)] metrics=\(widget.metrics.count)"
          case let .promoCarousel(promo):
            return "  • promo [\(block.kindLabel)] slides=\(promo.slideCount)"
          case let .teamGrid(team):
            return "  • team [\(block.kindLabel)] members=\(team.memberCount)"
          }
        }
        return """
        Pipeline OK — \(hub.workspace.slug)
        \(blockLines.joined(separator: "\n"))
        """
      }
    }

    addActionButton("8. Strict vs lenient on string priority") { [weak self] in
      self?.runMapping("Strict vs lenient") {
        guard let self else { return "Unavailable" }
        let data = try FKModelMappingExampleComplexPayloadSupport.loadFixture()
        let payload = try FKResponseEnvelopeProcessor(configuration: .standard).process(data: data).payload
        let dictionary = try JSONSerialization.jsonObject(with: payload) as! [String: Any]
        let feedPage = dictionary["feed_page"] as! [String: Any]
        let hub = try self.decodeHub(from: data)

        var strictConfiguration = FKModelMappingConfiguration.strict
        strictConfiguration.keyStrategy = .useDefaultKeys
        let strictMapper = FKModelMapper(
          configuration: strictConfiguration,
          transformRegistry: FKTransformRegistry()
        )

        let strictResult: String
        do {
          _ = try strictMapper.decode(FKModelMappingDemoHubFeedPage.self, from: feedPage)
          strictResult = "unexpected success"
        } catch {
          strictResult = FKModelMappingExampleSupport.describe(error: error)
        }

        let lenientPage = hub.feedPage
        return """
        Strict (.strict, empty transform registry):
        \(strictResult)

        Lenient (lenientAPI + default registry):
        decoded \(lenientPage.blocks.count) blocks, first priority=\(lenientPage.blocks.first.map(self.priorityLabel) ?? "-")
        """
      }
    }
  }

  private func decodeHub(from data: Data) throws -> FKModelMappingDemoComplexHubPayload {
    let mapper = FKModelMapper(configuration: configuration)
    let payload = try FKResponseEnvelopeProcessor(configuration: .standard)
      .process(data: data).payload
    let dictionary = try JSONSerialization.jsonObject(with: payload) as! [String: Any]
    return try mapper.decode(FKModelMappingDemoComplexHubPayload.self, from: dictionary)
  }

  private func priorityLabel(for block: FKModelMappingDemoHubBlock) -> String {
    switch block {
    case let .heroBanner(value): return String(value.priority)
    case let .articleList(value): return String(value.priority)
    case let .kpiWidget(value): return String(value.priority)
    case let .promoCarousel(value): return String(value.priority)
    case let .teamGrid(value): return String(value.priority)
    }
  }
}
