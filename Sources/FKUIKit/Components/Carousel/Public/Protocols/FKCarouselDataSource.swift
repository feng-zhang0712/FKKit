import UIKit

/// Supplies page content for ``FKCarousel``.
@MainActor
public protocol FKCarouselDataSource: AnyObject {
  /// Returns the number of logical pages.
  func numberOfPages(in carousel: FKCarousel) -> Int

  /// Returns a view for the page at `index`, reusing `view` when possible.
  func carousel(_ carousel: FKCarousel, viewForPageAt index: Int, reusing view: UIView?) -> UIView
}
