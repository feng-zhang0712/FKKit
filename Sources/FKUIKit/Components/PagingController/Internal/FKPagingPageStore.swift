import UIKit

@MainActor
final class FKPagingPageStore {
  private var eagerControllers: [UIViewController]
  private var lazyProvider: ((Int) -> UIViewController)?
  private var cache: [Int: UIViewController] = [:]
  private var identifierToIndex: [ObjectIdentifier: Int] = [:]

  private(set) var pageCount: Int

  init(viewControllers: [UIViewController]) {
    eagerControllers = viewControllers
    pageCount = viewControllers.count
    for (index, controller) in viewControllers.enumerated() {
      identifierToIndex[ObjectIdentifier(controller)] = index
    }
  }

  init(pageCount: Int, provider: @escaping (Int) -> UIViewController) {
    eagerControllers = []
    self.pageCount = max(0, pageCount)
    lazyProvider = provider
  }

  func controller(at index: Int) -> UIViewController? {
    guard index >= 0, index < pageCount else { return nil }
    if !eagerControllers.isEmpty {
      let controller = eagerControllers[index]
      identifierToIndex[ObjectIdentifier(controller)] = index
      return controller
    }
    if let cached = cache[index] {
      identifierToIndex[ObjectIdentifier(cached)] = index
      return cached
    }
    guard let lazyProvider else { return nil }
    let controller = lazyProvider(index)
    cache[index] = controller
    identifierToIndex[ObjectIdentifier(controller)] = index
    return controller
  }

  func index(of controller: UIViewController) -> Int? {
    if let mapped = identifierToIndex[ObjectIdentifier(controller)] { return mapped }
    if !eagerControllers.isEmpty { return eagerControllers.firstIndex(of: controller) }
    return cache.first(where: { $0.value === controller })?.key
  }

  func preload(around center: Int, range: Int) {
    guard range > 0 else { return }
    let lower = max(0, center - range)
    let upper = min(pageCount - 1, center + range)
    guard lower <= upper else { return }
    for index in lower...upper {
      _ = controller(at: index)
    }
  }

  func compactCache(selectedIndex: Int, retention: FKPagingRetentionPolicy) {
    guard eagerControllers.isEmpty else { return }
    switch retention {
    case .keepAll:
      return
    case .keepNear(let distance):
      let safeDistance = max(0, distance)
      let lower = max(0, selectedIndex - safeDistance)
      let upper = min(pageCount - 1, selectedIndex + safeDistance)
      cache = cache.filter { index, _ in
        index >= lower && index <= upper
      }
      identifierToIndex = identifierToIndex.filter { _, index in
        index >= lower && index <= upper
      }
    }
  }

  func reset(
    pageCount: Int,
    provider: ((Int) -> UIViewController)?,
    controllers: [UIViewController]
  ) {
    eagerControllers = controllers
    lazyProvider = provider
    cache.removeAll()
    identifierToIndex.removeAll()
    self.pageCount = max(0, pageCount)
    if !controllers.isEmpty {
      for (index, controller) in controllers.enumerated() {
        identifierToIndex[ObjectIdentifier(controller)] = index
      }
    }
  }
}
