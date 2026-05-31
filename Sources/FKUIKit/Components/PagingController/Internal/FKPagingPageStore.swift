import UIKit

@MainActor
final class FKPagingPageStore {
  private var eagerControllers: [UIViewController]
  private var lazyProvider: ((Int) -> UIViewController)?
  private var cache: [Int: UIViewController] = [:]
  private var identifierToIndex: [ObjectIdentifier: Int] = [:]

  private(set) var pageCount: Int

  var isEagerMode: Bool { !eagerControllers.isEmpty }

  init(viewControllers: [UIViewController]) {
    eagerControllers = viewControllers
    pageCount = viewControllers.count
    rebuildIdentifierMapForEager()
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

  func cachedController(at index: Int) -> UIViewController? {
    guard index >= 0, index < pageCount else { return nil }
    if !eagerControllers.isEmpty {
      return eagerControllers[index]
    }
    return cache[index]
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

  func compactCache(
    selectedIndex: Int,
    retention: FKPagingRetentionPolicy,
    onEvict: ((Int, UIViewController) -> Void)? = nil
  ) {
    guard eagerControllers.isEmpty else { return }
    switch retention {
    case .keepAll:
      return
    case .keepNear(let distance):
      let safeDistance = max(0, distance)
      let lower = max(0, selectedIndex - safeDistance)
      let upper = min(pageCount - 1, selectedIndex + safeDistance)
      let evicted = cache.filter { index, _ in
        index < lower || index > upper
      }
      for (index, controller) in evicted {
        onEvict?(index, controller)
        FKPagingScrollUtilities.detachFromParentIfNeeded(controller)
        identifierToIndex.removeValue(forKey: ObjectIdentifier(controller))
      }
      cache = cache.filter { index, _ in
        index >= lower && index <= upper
      }
    }
  }

  @discardableResult
  func invalidatePage(at index: Int) -> UIViewController? {
    if !eagerControllers.isEmpty {
      guard index >= 0, index < eagerControllers.count else { return nil }
      let removed = eagerControllers[index]
      identifierToIndex.removeValue(forKey: ObjectIdentifier(removed))
      return removed
    }
    guard let removed = cache.removeValue(forKey: index) else { return nil }
    FKPagingScrollUtilities.detachFromParentIfNeeded(removed)
    identifierToIndex.removeValue(forKey: ObjectIdentifier(removed))
    return removed
  }

  @discardableResult
  func replaceEagerController(at index: Int, with controller: UIViewController) -> UIViewController? {
    guard !eagerControllers.isEmpty, index >= 0, index < eagerControllers.count else { return nil }
    let old = eagerControllers[index]
    eagerControllers[index] = controller
    identifierToIndex.removeValue(forKey: ObjectIdentifier(old))
    identifierToIndex[ObjectIdentifier(controller)] = index
    return old
  }

  func syncPageCount(_ count: Int, onEvict: ((Int, UIViewController) -> Void)? = nil) {
    let newCount = max(0, count)
    if !eagerControllers.isEmpty {
      if newCount < eagerControllers.count {
        for index in newCount..<eagerControllers.count {
          let controller = eagerControllers[index]
          onEvict?(index, controller)
          FKPagingScrollUtilities.detachFromParentIfNeeded(controller)
          identifierToIndex.removeValue(forKey: ObjectIdentifier(controller))
        }
        eagerControllers = Array(eagerControllers.prefix(newCount))
      }
      pageCount = eagerControllers.count
      return
    }
    if newCount < pageCount {
      for (index, controller) in cache where index >= newCount {
        onEvict?(index, controller)
        FKPagingScrollUtilities.detachFromParentIfNeeded(controller)
        identifierToIndex.removeValue(forKey: ObjectIdentifier(controller))
      }
      cache = cache.filter { $0.key < newCount }
    }
    pageCount = newCount
  }

  func forEachCachedPage(_ body: (Int, UIViewController) -> Void) {
    if !eagerControllers.isEmpty {
      for (index, controller) in eagerControllers.enumerated() {
        body(index, controller)
      }
      return
    }
    for (index, controller) in cache {
      body(index, controller)
    }
  }

  func reset(
    pageCount: Int,
    provider: ((Int) -> UIViewController)?,
    controllers: [UIViewController],
    onEvict: ((Int, UIViewController) -> Void)? = nil
  ) {
    forEachCachedPage { index, controller in
      onEvict?(index, controller)
      FKPagingScrollUtilities.detachFromParentIfNeeded(controller)
    }
    eagerControllers = controllers
    lazyProvider = provider
    cache.removeAll()
    identifierToIndex.removeAll()
    self.pageCount = max(0, pageCount)
    if !controllers.isEmpty {
      rebuildIdentifierMapForEager()
    }
  }

  private func rebuildIdentifierMapForEager() {
    identifierToIndex.removeAll()
    for (index, controller) in eagerControllers.enumerated() {
      identifierToIndex[ObjectIdentifier(controller)] = index
    }
  }
}
