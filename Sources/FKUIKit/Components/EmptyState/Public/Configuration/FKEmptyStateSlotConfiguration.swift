import UIKit

/// Optional composition slots inserted into the empty-state stack.
///
/// Slots host custom views at fixed positions (header, media, content, actions, footer).
/// The library does not force-size slot content; callers own intrinsic size or internal constraints.
///
/// Prefer ``FKEmptyStateLayoutConfiguration/segmentSpacing`` for spacing between standard blocks
/// (image, title, description, buttons). Slots are for supplementary content, not layout spacers.
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
