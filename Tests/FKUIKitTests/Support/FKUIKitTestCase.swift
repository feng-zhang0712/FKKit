import FKUIKit
import UIKit
import XCTest

/// Base test case for UIKit-heavy FKUIKit tests.
///
/// Subclasses inherit `@MainActor` isolation so view/controller setup runs on the main thread
/// under Swift 6 strict concurrency.
@MainActor
class FKUIKitTestCase: XCTestCase {}
