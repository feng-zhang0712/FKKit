import FKCoreKit
import XCTest

final class NSAttributedStringExtensionTests: XCTestCase {
  func testFullRangeCoversEntireStringLength() {
    let attributed = NSAttributedString(string: "fkkit")
    XCTAssertEqual(attributed.fk_fullRange, NSRange(location: 0, length: 5))
  }

  func testApplyingAttributesReturnsCopyWithMergedAttributes() {
    let attributed = NSAttributedString(string: "title")
    let styled = attributed.fk_applying(attributes: [.kern: 2])

    var range = NSRange(location: 0, length: 0)
    let kern = styled.attribute(.kern, at: 0, effectiveRange: &range) as? Int
    XCTAssertEqual(kern, 2)
    XCTAssertEqual(range, attributed.fk_fullRange)
  }
}
