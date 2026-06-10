import UIKit

extension FKTag {
  // MARK: - Leading icon

  @discardableResult
  func ensureLeadingIconView() -> UIImageView {
    if let leadingIconView { return leadingIconView }

    let view = UIImageView()
    view.contentMode = .center
    view.isUserInteractionEnabled = false
    view.autoresizingMask = []
    addSubview(view)
    leadingIconView = view
    setNeedsLayout()
    return view
  }

  func releaseLeadingIconView() {
    leadingIconView?.removeFromSuperview()
    leadingIconView = nil
  }
}
