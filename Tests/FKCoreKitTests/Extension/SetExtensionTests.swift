import FKCoreKit
import XCTest

final class SetExtensionTests: XCTestCase {
  func testInsertingAndRemovingReturnNewSetsWithoutMutatingOriginal() {
    let original: Set = ["a", "b"]
    let inserted = original.fk_inserting("c")
    let removed = original.fk_removing("a")

    XCTAssertEqual(original, ["a", "b"])
    XCTAssertEqual(inserted, ["a", "b", "c"])
    XCTAssertEqual(removed, ["b"])
  }

  func testFormUnionMergesSequenceIntoMutableSet() {
    var set: Set = ["x"]
    set.fk_formUnion(from: ["y", "z"])

    XCTAssertEqual(set, ["x", "y", "z"])
  }
}
