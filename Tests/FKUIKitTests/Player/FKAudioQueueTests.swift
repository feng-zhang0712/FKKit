import FKUIKit
import XCTest

@MainActor
final class FKAudioQueueTests: FKUIKitTestCase {
  private func makeItem(id: String) -> FKAudioItem {
    FKAudioItem(
      id: id,
      source: .url(URL(string: "https://audio.example.com/\(id).mp3")!),
      title: id
    )
  }

  func testSequentialAdvanceStopsAtEnd() {
    let queue = FKAudioQueue(mode: .sequential)
    queue.replace([makeItem(id: "a"), makeItem(id: "b")])

    XCTAssertEqual(queue.currentItem?.id, "a")
    XCTAssertEqual(queue.advance()?.id, "b")
    XCTAssertNil(queue.advance())
    XCTAssertEqual(queue.currentItem?.id, "b")
  }

  func testRepeatAllWrapsToFirstItem() {
    let queue = FKAudioQueue(mode: .repeatAll)
    queue.replace([makeItem(id: "a"), makeItem(id: "b")])

    _ = queue.advance()
    XCTAssertEqual(queue.advance()?.id, "a")
  }

  func testRepeatOneKeepsCurrentItem() {
    let queue = FKAudioQueue(mode: .repeatOne)
    queue.replace([makeItem(id: "a"), makeItem(id: "b")])
    queue.setCurrentIndex(1)

    XCTAssertEqual(queue.advance()?.id, "b")
    XCTAssertEqual(queue.advance()?.id, "b")
  }

  func testRemoveCurrentItemFallsBackToNearestRemainingIndex() {
    let queue = FKAudioQueue(mode: .sequential)
    queue.replace([makeItem(id: "a"), makeItem(id: "b"), makeItem(id: "c")])
    queue.setCurrentIndex(1)

    queue.remove(at: 1)

    XCTAssertEqual(queue.currentItem?.id, "c")
    XCTAssertEqual(queue.items.map(\.id), ["a", "c"])
  }

  func testInsertNextInsertsAfterCurrentIndex() {
    let queue = FKAudioQueue(mode: .sequential)
    queue.replace([makeItem(id: "a"), makeItem(id: "c")])
    queue.setCurrentIndex(0)

    queue.insertNext(makeItem(id: "b"))

    XCTAssertEqual(queue.items.map(\.id), ["a", "b", "c"])
  }

  func testToMediaPlaylistUsesCurrentIndexAsStart() {
    let queue = FKAudioQueue(mode: .sequential)
    queue.replace([makeItem(id: "a"), makeItem(id: "b")], startIndex: 1)

    let playlist = queue.toMediaPlaylist(id: "test-playlist")

    XCTAssertEqual(playlist.id, "test-playlist")
    XCTAssertEqual(playlist.startIndex, 1)
    XCTAssertEqual(playlist.items.count, 2)
  }
}
