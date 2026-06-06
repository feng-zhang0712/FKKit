import UIKit

/// Optional composition slots inserted into the empty-state stack.
///
/// Slots are never force-sized by the library; callers own intrinsic size or constraints inside the slot view.
public struct FKEmptyStateSlotConfiguration {
  public var header: UIView?
  public var media: UIView?
  public var content: UIView?
  public var actions: UIView?
  public var footer: UIView?

  public init(
    header: UIView? = nil,
    media: UIView? = nil,
    content: UIView? = nil,
    actions: UIView? = nil,
    footer: UIView? = nil
  ) {
    self.header = header
    self.media = media
    self.content = content
    self.actions = actions
    self.footer = footer
  }
}
