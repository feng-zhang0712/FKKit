import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKAvatarSwiftUIDemoRoot: View {
  @State private var presence: FKPresenceState = .online
  @State private var showsPresence = true
  @State private var avatarConfig: FKAvatarConfiguration = {
    var config = FKAvatarDefaults.configuration
    config.layout.size = .l
    return config
  }()

  private let groupMembers = FKAvatarExampleSupport.sampleGroupMembers()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKAvatarRepresentable(
            configuration: avatarConfig,
            displayName: "SwiftUI User",
            imageURL: FKAvatarExampleSupport.avatarURL(id: 64, size: 160),
            presenceState: presence,
            showsPresenceIndicator: showsPresence
          )
          .frame(maxWidth: .infinity, minHeight: 80)
        } header: {
          Text("FKAvatarRepresentable")
        } footer: {
          Text("Wraps FKAvatar with configuration, content, and runtime presence bindings.")
        }

        Section("FKAvatarGroupRepresentable") {
          FKAvatarGroupRepresentable(
            configuration: {
              var config = FKAvatarGroupConfiguration()
              config.borderStyle = .custom(color: UIColor.systemBackground, width: 2)
              return config
            }(),
            avatars: groupMembers
          )
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }

        Section("FKPresenceIndicatorView") {
          HStack(spacing: 16) {
            FKPresenceIndicatorView(state: .online)
            FKPresenceIndicatorView(state: .away)
            FKPresenceIndicatorView(state: .busy)
            FKPresenceIndicatorView(state: .offline)
          }
          .frame(maxWidth: .infinity)
        }

        Section("Presence binding") {
          Toggle("Show presence", isOn: $showsPresence)
          Picker("State", selection: Binding(
            get: { presenceTag(for: presence) },
            set: { presence = presenceState(for: $0) }
          )) {
            Text("Online").tag(0)
            Text("Away").tag(1)
            Text("Busy").tag(2)
            Text("Offline").tag(3)
          }
        }

        Section("Avatar size") {
          Picker("Size", selection: Binding(
            get: { sizeTag(for: avatarConfig.layout.size) },
            set: { tag in avatarConfig.layout.size = size(for: tag) }
          )) {
            Text("S").tag(0)
            Text("M").tag(1)
            Text("L").tag(2)
            Text("XL").tag(3)
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("SwiftUI bridges")
    }
    .navigationViewStyle(.stack)
  }

  private func sizeTag(for size: FKAvatarSize) -> Int {
    switch size {
    case .s: 0
    case .l: 2
    case .xl: 3
    default: 1
    }
  }

  private func size(for tag: Int) -> FKAvatarSize {
    switch tag {
    case 0: .s
    case 2: .l
    case 3: .xl
    default: .m
    }
  }

  private func presenceTag(for state: FKPresenceState) -> Int {
    switch state {
    case .online: 0
    case .away: 1
    case .busy: 2
    case .offline: 3
    case .custom: 0
    }
  }

  private func presenceState(for tag: Int) -> FKPresenceState {
    switch tag {
    case 1: .away
    case 2: .busy
    case 3: .offline
    default: .online
    }
  }
}

final class FKAvatarExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridges"

    let host = UIHostingController(rootView: FKAvatarSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
  }
}
#endif

#if !canImport(SwiftUI)
import UIKit

final class FKAvatarExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridges"
    view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = "SwiftUI is unavailable in this build configuration."
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
#endif
