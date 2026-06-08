#if canImport(UIKit)
  import UIKit

  /// Thread-safe in-memory image cache backed by `NSCache`.
  final class FKImageMemoryCache: @unchecked Sendable {
    private final class Entry {
      let image: UIImage
      init(_ image: UIImage) { self.image = image }
    }

    private let cache = NSCache<NSString, Entry>()
    private let lock = NSLock()
    private var configuredCostLimit: Int
    private var configuredCountLimit: Int
    private var trackedKeys: Set<String> = []
    private var trackedCosts: [String: Int] = [:]

    init(costLimit: Int, countLimit: Int) {
      configuredCostLimit = costLimit
      configuredCountLimit = countLimit
      applyLimits(costLimit: costLimit, countLimit: countLimit)
    }

    func applyLimits(costLimit: Int, countLimit: Int) {
      configuredCostLimit = max(0, costLimit)
      configuredCountLimit = max(0, countLimit)
      lock.lock()
      cache.totalCostLimit = configuredCostLimit
      cache.countLimit = configuredCountLimit
      lock.unlock()
    }

    func image(forKey key: String) -> UIImage? {
      lock.lock()
      defer { lock.unlock() }
      guard let entry = cache.object(forKey: key as NSString) else {
        trackedKeys.remove(key)
        trackedCosts.removeValue(forKey: key)
        return nil
      }
      return entry.image
    }

    func store(_ image: UIImage, forKey key: String) {
      let cost = Self.cost(for: image)
      lock.lock()
      cache.setObject(Entry(image), forKey: key as NSString, cost: cost)
      trackedKeys.insert(key)
      trackedCosts[key] = cost
      lock.unlock()
    }

    func removeImage(forKey key: String) {
      lock.lock()
      cache.removeObject(forKey: key as NSString)
      trackedKeys.remove(key)
      trackedCosts.removeValue(forKey: key)
      lock.unlock()
    }

    func removeAllImages() {
      lock.lock()
      cache.removeAllObjects()
      trackedKeys.removeAll()
      trackedCosts.removeAll()
      lock.unlock()
    }

    func clearAll() {
      removeAllImages()
      applyLimits(costLimit: configuredCostLimit, countLimit: configuredCountLimit)
    }

    func trim(toCost targetCost: Int) {
      lock.lock()
      defer {
        cache.totalCostLimit = configuredCostLimit
        cache.countLimit = configuredCountLimit
        lock.unlock()
      }

      reconcileTrackedKeysLocked()

      if targetCost <= 0 {
        cache.removeAllObjects()
        trackedKeys.removeAll()
        trackedCosts.removeAll()
        return
      }

      var total = trackedCosts.values.reduce(0, +)
      let sortedKeys = trackedKeys.sorted { (trackedCosts[$0] ?? 0) > (trackedCosts[$1] ?? 0) }
      for key in sortedKeys where total > targetCost {
        cache.removeObject(forKey: key as NSString)
        total -= trackedCosts[key] ?? 0
        trackedKeys.remove(key)
        trackedCosts.removeValue(forKey: key)
      }
    }

    func statistics() -> (entryCount: Int, costBytes: Int) {
      lock.lock()
      defer { lock.unlock() }
      reconcileTrackedKeysLocked()
      let cost = trackedCosts.values.reduce(0, +)
      return (trackedKeys.count, cost)
    }

    private func reconcileTrackedKeysLocked() {
      var staleKeys: [String] = []
      for key in trackedKeys where cache.object(forKey: key as NSString) == nil {
        staleKeys.append(key)
      }
      for key in staleKeys {
        trackedKeys.remove(key)
        trackedCosts.removeValue(forKey: key)
      }
    }

    static func cost(for image: UIImage) -> Int {
      guard let cgImage = image.cgImage else { return 1 }
      return cgImage.width * cgImage.height * 4
    }
  }
#endif
