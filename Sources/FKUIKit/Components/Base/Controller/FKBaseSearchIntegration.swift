import UIKit

/// Minimal wiring for embedding a `UISearchController` in navigation-item–based apps.
///
/// Call ``install(_:on:hidesNavigationBarDuringPresentation:)`` from the host view controller
/// (typically after creating the search controller in ``setupUI()`` or ``setupBindings()``).
public enum FKBaseSearchIntegration {

  /// Attaches the search controller to the host’s navigation item and sets presentation context.
  ///
  /// - Parameters:
  ///   - searchController: Configured search controller (you still own its `searchResultsUpdater`, etc.).
  ///   - host: Usually `self` when embedded in a `UINavigationController`.
  ///   - hidesNavigationBarDuringPresentation: Forwarded to `UISearchController`; matches UIKit defaults when `true`.
  public static func install(
    _ searchController: UISearchController,
    on host: UIViewController,
    hidesNavigationBarDuringPresentation: Bool = true
  ) {
    host.definesPresentationContext = true
    host.navigationItem.searchController = searchController
    searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarDuringPresentation
  }

  /// Clears navigation-item search UI on the host (does not dismiss active presentation alone).
  public static func uninstall(from host: UIViewController) {
    host.navigationItem.searchController = nil
  }
}
