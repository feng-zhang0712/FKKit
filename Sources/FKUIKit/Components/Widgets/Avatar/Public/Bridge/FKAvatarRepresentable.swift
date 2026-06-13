#if canImport(SwiftUI)
  import SwiftUI
  import UIKit

  /// SwiftUI wrapper around ``FKAvatar``.
  public struct FKAvatarRepresentable: UIViewRepresentable {
    public var configuration: FKAvatarConfiguration
    public var displayName: String?
    public var imageURL: URL?
    public var image: UIImage?
    public var isEnabled: Bool
    public var presenceState: FKPresenceState?
    public var showsPresenceIndicator: Bool?

    public init(
      configuration: FKAvatarConfiguration = FKAvatarDefaults.configuration,
      displayName: String? = nil,
      imageURL: URL? = nil,
      image: UIImage? = nil,
      isEnabled: Bool = true,
      presenceState: FKPresenceState? = nil,
      showsPresenceIndicator: Bool? = nil
    ) {
      self.configuration = configuration
      self.displayName = displayName
      self.imageURL = imageURL
      self.image = image
      self.isEnabled = isEnabled
      self.presenceState = presenceState
      self.showsPresenceIndicator = showsPresenceIndicator
    }

    public func makeUIView(context: Context) -> FKAvatar {
      let view = FKAvatar(configuration: configuration)
      apply(to: view)
      return view
    }

    public func updateUIView(_ uiView: FKAvatar, context: Context) {
      uiView.configuration = configuration
      apply(to: uiView)
    }

    private func apply(to view: FKAvatar) {
      view.isEnabled = isEnabled
      if view.displayName != displayName {
        view.displayName = displayName
      }
      if let showsPresenceIndicator {
        view.showsPresenceIndicator = showsPresenceIndicator
      }
      if let presenceState {
        view.presenceState = presenceState
      }
      if let image {
        view.image = image
      } else {
        if view.image != nil {
          view.image = nil
        }
        if view.imageURL != imageURL {
          view.setImageURL(imageURL, placeholder: nil)
        }
      }
    }
  }
#endif
