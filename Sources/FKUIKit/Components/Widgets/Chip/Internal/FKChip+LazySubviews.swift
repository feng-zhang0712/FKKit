import UIKit

extension FKChip {
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

  // MARK: - Remove affordance

  @discardableResult
  func ensureRemoveImageView() -> UIImageView {
    if let removeImageView { return removeImageView }

    let view = UIImageView()
    view.contentMode = .center
    view.isUserInteractionEnabled = false
    if let captionLabel = subviews.first(where: { $0 is UILabel }) {
      insertSubview(view, aboveSubview: captionLabel)
    } else {
      addSubview(view)
    }
    removeImageView = view
    setNeedsLayout()
    return view
  }

  func releaseRemoveImageView() {
    removeImageView?.removeFromSuperview()
    removeImageView = nil
  }
}
