import UIKit

extension FKButton {
  open override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    MainActor.assumeIsolated {
      flushPendingRefresh()
    }
  }
}
