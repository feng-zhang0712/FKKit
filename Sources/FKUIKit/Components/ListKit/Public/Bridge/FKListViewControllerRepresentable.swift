#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Embeds ``FKDiffableTableViewController`` in SwiftUI.
public struct FKDiffableTableViewControllerRepresentable: UIViewControllerRepresentable {
  public var configuration: FKListConfiguration
  public var style: UITableView.Style
  public var makeViewController: ((FKListConfiguration, UITableView.Style) -> FKDiffableTableViewController)?

  public init(
    configuration: FKListConfiguration = FKListDefaults.defaultConfiguration,
    style: UITableView.Style = .plain,
    makeViewController: ((FKListConfiguration, UITableView.Style) -> FKDiffableTableViewController)? = nil
  ) {
    self.configuration = configuration
    self.style = style
    self.makeViewController = makeViewController
  }

  public func makeUIViewController(context: Context) -> FKDiffableTableViewController {
    let controller = makeViewController?(configuration, style)
      ?? FKDiffableTableViewController(configuration: configuration, style: style)
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKDiffableTableViewController, context: Context) {
    if uiViewController.configuration != configuration {
      uiViewController.configuration = configuration
    }
  }
}

/// Embeds ``FKDiffableCollectionViewController`` in SwiftUI.
public struct FKDiffableCollectionViewControllerRepresentable: UIViewControllerRepresentable {
  public var configuration: FKListConfiguration
  public var layoutPreset: FKListCollectionLayoutPreset
  public var makeViewController: ((FKListConfiguration, FKListCollectionLayoutPreset) -> FKDiffableCollectionViewController)?

  public init(
    configuration: FKListConfiguration = FKListDefaults.defaultConfiguration,
    layoutPreset: FKListCollectionLayoutPreset = .list,
    makeViewController: ((FKListConfiguration, FKListCollectionLayoutPreset) -> FKDiffableCollectionViewController)? = nil
  ) {
    self.configuration = configuration
    self.layoutPreset = layoutPreset
    self.makeViewController = makeViewController
  }

  public func makeUIViewController(context: Context) -> FKDiffableCollectionViewController {
    let controller = makeViewController?(configuration, layoutPreset)
      ?? FKDiffableCollectionViewController(configuration: configuration, layoutPreset: layoutPreset)
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKDiffableCollectionViewController, context: Context) {
    if uiViewController.configuration != configuration {
      uiViewController.configuration = configuration
    }
    if uiViewController.layoutPreset != layoutPreset {
      uiViewController.layoutPreset = layoutPreset
    }
  }
}
#endif
