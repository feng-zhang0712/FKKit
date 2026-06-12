#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKAvatarGroup``.
  public struct FKAvatarGroupRepresentable: UIViewRepresentable {
    public var configuration: FKAvatarGroupConfiguration
    public var avatars: [FKAvatarContent]
    public var onOverflowTap: (() -> Void)?
    public var onAvatarTap: ((Int) -> Void)?

    public init(
      configuration: FKAvatarGroupConfiguration = FKAvatarGroupDefaults.configuration,
      avatars: [FKAvatarContent] = [],
      onOverflowTap: (() -> Void)? = nil,
      onAvatarTap: ((Int) -> Void)? = nil
    ) {
      self.configuration = configuration
      self.avatars = avatars
      self.onOverflowTap = onOverflowTap
      self.onAvatarTap = onAvatarTap
    }

    public func makeUIView(context: Context) -> FKAvatarGroup {
      let view = FKAvatarGroup(configuration: configuration, avatars: avatars)
      view.onOverflowTap = onOverflowTap
      view.onAvatarTap = onAvatarTap
      return view
    }

    public func updateUIView(_ uiView: FKAvatarGroup, context: Context) {
      uiView.configuration = configuration
      uiView.avatars = avatars
      uiView.onOverflowTap = onOverflowTap
      uiView.onAvatarTap = onAvatarTap
    }
  }
#endif
