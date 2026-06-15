import FKUIKit
import UIKit

// MARK: - Model

/// Demo feed post stored in the ListKit payload side table.
struct FKListKitExampleFeedPost: Sendable, FKListImagePrefetchProviding {
  static let cellTypeIdentifier = "FKListKitExampleFeedPostCell"
  static let avatarSize = CGSize(width: 40, height: 40)
  static let mediaSize = CGSize(width: 320, height: 180)

  let id: FKListItemID
  let authorName: String
  let avatarPhotoID: Int
  let body: String
  let mediaPhotoID: Int?
  var likeCount: Int

  var listPrefetchImageRequests: [FKListImagePrefetchRequest] {
    var requests = [
      FKListImagePrefetchRequest(
        url: Self.remoteURL(id: avatarPhotoID, width: 80, height: 80),
        targetSize: Self.avatarSize
      ),
    ]
    if let mediaPhotoID {
      requests.append(
        FKListImagePrefetchRequest(
          url: Self.remoteURL(id: mediaPhotoID, width: 640, height: 360),
          targetSize: Self.mediaSize
        )
      )
    }
    return requests
  }

  private static func remoteURL(id: Int, width: Int, height: Int) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
  }
}

// MARK: - API

enum FKListKitExampleComplexFeedAPI {
  static let pageSize = 10
  static let maxPages = 4

  private static let bodies: [String] = [
    "Weekend hike photos — FKImageView + FKListImagePrefetchHelper keep scrolling smooth.",
    "Short update.",
    "Shipping ListKit v3: reconfigure for likes, prefetch for avatars and media, and cached dynamic heights via FKListHeightCache.",
    "One image, multi-line copy, and a like button. This row uses a custom cell registered with ListKit.",
  ]

  static func fetch(page: Int, delay: TimeInterval = 0.7) async throws -> (posts: [FKListKitExampleFeedPost], hasMorePages: Bool) {
    let nanos = UInt64(max(0, delay) * 1_000_000_000)
    try await Task.sleep(nanoseconds: nanos)
    guard page >= 1 else { return ([], false) }
    let posts = (0 ..< pageSize).map { index in
      let global = (page - 1) * pageSize + index
      let body = bodies[global % bodies.count]
      return FKListKitExampleFeedPost(
        id: FKListItemID("post-\(page)-\(index)"),
        authorName: "Traveler \(global + 1)",
        avatarPhotoID: 60 + (global % 15),
        body: body,
        mediaPhotoID: global.isMultiple(of: 2) ? 100 + (global % 20) : nil,
        likeCount: global * 3
      )
    }
    return (posts, page < maxPages)
  }

  static func makeSnapshot(posts: [FKListKitExampleFeedPost]) -> FKListSnapshot {
    let items = posts.map { post in
      FKListItem.custom(id: post.id, cellTypeIdentifier: FKListKitExampleFeedPost.cellTypeIdentifier)
    }
    return FKListSnapshot(items: items)
  }

  static func makeFetchResult(posts: [FKListKitExampleFeedPost], hasMorePages: Bool) -> FKListFetchResult {
    FKListFetchResult(snapshot: makeSnapshot(posts: posts), hasMorePages: hasMorePages)
  }

  static func estimatedRowHeight(for post: FKListKitExampleFeedPost, width: CGFloat, cache: FKListHeightCache) -> CGFloat {
    if let cached = cache.height(for: post.id, width: width) {
      return cached
    }
    let bodyFont = UIFont.preferredFont(forTextStyle: .body)
    let horizontalInset: CGFloat = 16
    let textWidth = width - horizontalInset * 2
    let bodyHeight = FKListHeightCache.measuredTextHeight(
      post.body,
      font: bodyFont,
      width: max(1, textWidth),
      insets: .zero
    )
    var height: CGFloat = 12 + 40 + 8 + bodyHeight + 8
    if post.mediaPhotoID != nil {
      height += 180 + 8
    }
    height += 36 + 12
    cache.setHeight(height, for: post.id, width: width)
    return height
  }
}

// MARK: - Icons

enum FKListKitExampleRemoteImageURL {
  static func make(id: Int, width: Int = 80, height: Int = 80) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
  }
}
