import Foundation

/// Presentation of search-page body and results regions for ``FKSearchViewController``.
public struct FKSearchPresentationConfiguration: Sendable, Equatable {
  public var resultsMode: FKSearchResultsPresentationMode
  public var idleContent: FKSearchIdleContentPresentation

  public init(
    resultsMode: FKSearchResultsPresentationMode = .embeddedList,
    idleContent: FKSearchIdleContentPresentation = .listSnapshot
  ) {
    self.resultsMode = resultsMode
    self.idleContent = idleContent
  }

  /// v1 unified default: embedded list handles idle snapshots and search results.
  public static var unified: FKSearchPresentationConfiguration {
    FKSearchPresentationConfiguration()
  }

  /// Custom idle search page with embedded ListKit results.
  public static var customIdleEmbeddedResults: FKSearchPresentationConfiguration {
    FKSearchPresentationConfiguration(
      resultsMode: .embeddedList,
      idleContent: .customViewController
    )
  }

  /// Custom idle page; host handles result navigation (WeChat / PYSearch push style).
  public static var customIdleHostHandledResults: FKSearchPresentationConfiguration {
    FKSearchPresentationConfiguration(
      resultsMode: .hostHandled,
      idleContent: .customViewController
    )
  }

  /// Fully custom results child view controller with list-snapshot idle fallback on that surface.
  public static var customResultsViewController: FKSearchPresentationConfiguration {
    FKSearchPresentationConfiguration(
      resultsMode: .customViewController,
      idleContent: .listSnapshot
    )
  }
}
