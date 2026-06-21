import FKCoreKit
import Foundation

// MARK: - Embedded JSON value types

struct FKModelMappingDemoWorkspaceSettings: Sendable {
  let theme: String
  let density: String
  let betaEnabled: Bool
  let labs: [String]
}

extension FKModelMappingDemoWorkspaceSettings: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    theme = try container.decode(String.self, forKey: .theme)
    density = try container.decode(String.self, forKey: .density)
    let flags = try container.nestedContainer(keyedBy: FlagKeys.self, forKey: .flags)
    betaEnabled = try flags.decode(Bool.self, forKey: .beta)
    labs = try flags.decode([String].self, forKey: .labs)
  }

  private enum CodingKeys: String, CodingKey {
    case theme, density, flags
  }

  private enum FlagKeys: String, CodingKey {
    case beta, labs
  }
}

struct FKModelMappingDemoLayoutRegion: Sendable {
  let region: String
  let widgets: [String]
}

extension FKModelMappingDemoLayoutRegion: Codable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    region = try container.decode(String.self, forKey: .region)
    widgets = try container.decode([String].self, forKey: .widgets)
  }

  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(region, forKey: .region)
    try container.encode(widgets, forKey: .widgets)
  }

  private enum CodingKeys: String, CodingKey {
    case region, widgets
  }
}

struct FKModelMappingDemoKPIMetric: Sendable {
  let label: String
  let value: String
  let delta: String?
}

extension FKModelMappingDemoKPIMetric: Codable {
  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    label = try container.decode(String.self, forKey: .label)
    value = try container.decode(String.self, forKey: .value)
    delta = try container.decodeIfPresent(String.self, forKey: .delta)
  }

  nonisolated func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(label, forKey: .label)
    try container.encode(value, forKey: .value)
    try container.encodeIfPresent(delta, forKey: .delta)
  }

  private enum CodingKeys: String, CodingKey {
    case label, value, delta
  }
}

// MARK: - Hub models

struct FKModelMappingDemoHubMeta: FKMappable, Sendable {
  let requestID: String
  let serverTime: Date?
  let span: String
  let durationMS: Int

  init(map: FKMap) throws {
    requestID = try map.value("request_id", as: String.self)
    serverTime = map.optionalValue("server_time", as: Date.self)
    span = try map.value("trace.span", as: String.self)
    durationMS = try map.value("trace.duration_ms", as: Int.self)
  }
}

struct FKModelMappingDemoHubOwner: FKMappable, Sendable {
  let userID: Int
  let displayName: String
  let emailEnabled: Bool
  let pushEnabled: Bool
  let channels: [String]
  let roles: [String]

  init(map: FKMap) throws {
    userID = try map.value("user_id", as: Int.self)
    displayName = try map.value("profile.display_name", as: String.self)
    emailEnabled = try map.value("profile.preferences.notifications.email", as: Bool.self)
    pushEnabled = try map.value("profile.preferences.notifications.push", as: Bool.self)
    channels = (0 ..< 4).compactMap { index in
      map.optionalValue("profile.preferences.notifications.channels[\(index)]", as: String.self)
    }
    roles = (0 ..< 3).compactMap { index in
      map.optionalValue("roles[\(index)]", as: String.self)
    }
  }
}

struct FKModelMappingDemoHubWorkspace: FKMappable, Sendable {
  let id: String
  let slug: String
  let displayName: String
  let owner: FKModelMappingDemoHubOwner
  let settings: FKModelMappingDemoWorkspaceSettings?
  let layoutRegions: [FKModelMappingDemoLayoutRegion]
  let createdAt: Date?
  let updatedAt: Date?
  let isActive: Bool

  init(map: FKMap) throws {
    id = try map.value("id", as: String.self)
    slug = try map.value("slug", as: String.self)
    displayName = try map.value("display_name", as: String.self)
    guard let ownerMap = map.nestedObject("owner") else {
      throw FKMappingError.keyNotFound(path: "owner")
    }
    owner = try FKModelMappingDemoHubOwner(map: ownerMap)
    let settingsTransform = FKModelMappingDemoEmbeddedJSONObjectTransform<FKModelMappingDemoWorkspaceSettings>()
    settings = try settingsTransform.transformFromJSON(map.optionalValue("settings_json", as: String.self))
    let layoutTransform = FKModelMappingDemoEmbeddedJSONArrayTransform<FKModelMappingDemoLayoutRegion>()
    layoutRegions = try layoutTransform.transformFromJSON(map.optionalValue("layout_json", as: String.self)) ?? []
    createdAt = map.optionalValue("created_at", as: Date.self)
    updatedAt = map.optionalValue("updated_at", as: Date.self)
    isActive = try map.value("status", as: Bool.self)
  }
}

struct FKModelMappingDemoHubSortProp: FKMappable, Sendable {
  let key: String
  let ascending: Bool

  init(map: FKMap) throws {
    key = try map.value("key", as: String.self)
    ascending = try map.value("value", as: Bool.self)
  }
}

struct FKModelMappingDemoHubFeedPage: FKMappable, Sendable {
  let blocks: [FKModelMappingDemoHubBlock]
  let total: Int
  let current: Int
  let size: Int
  let pages: Int
  let sortProps: [FKModelMappingDemoHubSortProp]

  init(map: FKMap) throws {
    blocks = try map.polymorphicArray("records", as: FKModelMappingDemoHubBlock.self)
    total = try map.value("total", as: Int.self)
    current = try map.value("current", as: Int.self)
    size = try map.value("size", as: Int.self)
    pages = try map.value("pages", as: Int.self)
    sortProps = (try? map.array("sort_props", as: FKModelMappingDemoHubSortProp.self)) ?? []
  }
}

struct FKModelMappingDemoHubFacets: FKMappable, Sendable {
  let blockTypes: [String]
  let enabledCounts: [String: Int]

  init(map: FKMap) throws {
    blockTypes = (0 ..< 4).compactMap { index in
      map.optionalValue("block_types[\(index)]", as: String.self)
    }
    enabledCounts = [
      "hero_banner": map.optionalValue("enabled_counts.hero_banner", as: Int.self),
      "article_list": map.optionalValue("enabled_counts.article_list", as: Int.self),
      "kpi_widget": map.optionalValue("enabled_counts.kpi_widget", as: Int.self),
    ].compactMapValues { $0 }
  }
}

struct FKModelMappingDemoHubLinks: FKMappable, Sendable {
  let next: URL?
  let previous: URL?

  init(map: FKMap) throws {
    next = map.optionalValue("next", as: URL.self)
    previous = map.optionalValue("prev", as: URL.self)
  }
}

struct FKModelMappingDemoComplexHubPayload: FKMappable, Sendable {
  let meta: FKModelMappingDemoHubMeta
  let workspace: FKModelMappingDemoHubWorkspace
  let feedPage: FKModelMappingDemoHubFeedPage
  let facets: FKModelMappingDemoHubFacets
  let links: FKModelMappingDemoHubLinks

  init(map: FKMap) throws {
    guard let metaMap = map.nestedObject("meta") else {
      throw FKMappingError.keyNotFound(path: "meta")
    }
    guard let workspaceMap = map.nestedObject("workspace") else {
      throw FKMappingError.keyNotFound(path: "workspace")
    }
    guard let feedPageMap = map.nestedObject("feed_page") else {
      throw FKMappingError.keyNotFound(path: "feed_page")
    }
    guard let facetsMap = map.nestedObject("facets") else {
      throw FKMappingError.keyNotFound(path: "facets")
    }
    guard let linksMap = map.nestedObject("links") else {
      throw FKMappingError.keyNotFound(path: "links")
    }
    meta = try FKModelMappingDemoHubMeta(map: metaMap)
    workspace = try FKModelMappingDemoHubWorkspace(map: workspaceMap)
    feedPage = try FKModelMappingDemoHubFeedPage(map: feedPageMap)
    facets = try FKModelMappingDemoHubFacets(map: facetsMap)
    links = try FKModelMappingDemoHubLinks(map: linksMap)
  }
}

// MARK: - Polymorphic feed blocks

enum FKModelMappingDemoHubBlock: FKPolymorphicDecodable, Sendable {
  case heroBanner(HeroBanner)
  case articleList(ArticleList)
  case kpiWidget(KPIWidget)
  case promoCarousel(PromoCarousel)
  case teamGrid(TeamGrid)

  struct HeroBanner: FKMappable, Sendable {
    let id: String
    let priority: Int
    let enabled: Bool
    let title: String
    let subtitle: String?
    let imageURL: URL
    let imageWidth: Int
    let dominantColor: String
    let ctaLabel: String
    let deepLink: URL

    init(map: FKMap) throws {
      id = try map.value("id", as: String.self)
      priority = try map.value("priority", as: Int.self)
      enabled = try map.value("enabled", as: Bool.self)
      title = try map.value("title", as: String.self)
      subtitle = map.optionalValue("subtitle", as: String.self)
      imageURL = try map.value("media.url", as: URL.self)
      imageWidth = try map.value("media.width", as: Int.self)
      dominantColor = try map.value("media.meta.dominant_color", as: String.self)
      ctaLabel = try map.value("cta.label", as: String.self)
      deepLink = try map.value("cta.deep_link", as: URL.self)
    }
  }

  struct ArticleList: FKMappable, Sendable {
    let id: String
    let priority: Int
    let title: String
    let articles: [Article]

    struct Article: FKMappable, Sendable {
      let id: String
      let headline: String
      let publishedAt: Date?
      let views: Int?
      let likes: Int

      init(map: FKMap) throws {
        id = try map.value("id", as: String.self)
        headline = try map.value("headline", as: String.self)
        publishedAt = map.optionalValue("published_at", as: Date.self)
        views = map.optionalValue("stats.views", as: Int.self)
        likes = try map.value("stats.likes", as: Int.self)
      }
    }

    init(map: FKMap) throws {
      id = try map.value("id", as: String.self)
      priority = try map.value("priority", as: Int.self)
      title = try map.value("title", as: String.self)
      articles = try map.array("articles", as: Article.self)
    }
  }

  struct KPIWidget: FKMappable, Sendable {
    let id: String
    let priority: Int
    let title: String
    let metrics: [FKModelMappingDemoKPIMetric]

    init(map: FKMap) throws {
      id = try map.value("id", as: String.self)
      priority = try map.value("priority", as: Int.self)
      title = try map.value("title", as: String.self)
      let transform = FKModelMappingDemoEmbeddedJSONArrayTransform<FKModelMappingDemoKPIMetric>()
      metrics = try transform.transformFromJSON(map.optionalValue("metrics_json", as: String.self)) ?? []
    }
  }

  struct PromoCarousel: FKMappable, Sendable {
    let id: String
    let priority: Int
    let enabled: Bool
    let slideCount: Int

    init(map: FKMap) throws {
      id = try map.value("id", as: String.self)
      priority = try map.value("priority", as: Int.self)
      enabled = try map.value("enabled", as: Bool.self)
      slideCount = (try? map.array("slides", as: Slide.self))?.count ?? 0
    }

    private struct Slide: FKMappable, Sendable {
      let image: String?

      init(map: FKMap) throws {
        image = map.optionalValue("image", as: String.self)
      }
    }
  }

  struct TeamGrid: FKMappable, Sendable {
    let id: String
    let priority: Int
    let enabled: Bool
    let memberCount: Int
    let firstMember: String?

    init(map: FKMap) throws {
      id = try map.value("id", as: String.self)
      priority = try map.value("priority", as: Int.self)
      enabled = try map.value("enabled", as: Bool.self)
      let members = try map.array("members", as: Member.self)
      memberCount = members.count
      firstMember = members.first?.name
    }

    private struct Member: FKMappable, Sendable {
      let name: String?

      init(map: FKMap) throws {
        name = map.optionalValue("name", as: String.self)
      }
    }
  }

  static func decode(from map: FKMap, typeValue: String) throws -> FKModelMappingDemoHubBlock {
    switch typeValue {
    case "hero_banner":
      return .heroBanner(try HeroBanner(map: map))
    case "article_list":
      return .articleList(try ArticleList(map: map))
    case "kpi_widget":
      return .kpiWidget(try KPIWidget(map: map))
    case "promo_carousel":
      return .promoCarousel(try PromoCarousel(map: map))
    case "team_grid":
      return .teamGrid(try TeamGrid(map: map))
    default:
      throw FKMappingError.typeMismatch(
        path: discriminatorKey,
        expected: "hero_banner|article_list|kpi_widget|promo_carousel|team_grid",
        actual: typeValue
      )
    }
  }
}

extension FKModelMappingDemoHubBlock {
  var kindLabel: String {
    switch self {
    case .heroBanner: return "hero_banner"
    case .articleList: return "article_list"
    case .kpiWidget: return "kpi_widget"
    case .promoCarousel: return "promo_carousel"
    case .teamGrid: return "team_grid"
    }
  }
}
