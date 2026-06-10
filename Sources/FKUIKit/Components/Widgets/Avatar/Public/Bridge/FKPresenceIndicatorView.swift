#if canImport(SwiftUI)
  import SwiftUI

  /// Native SwiftUI presence dot mirroring ``FKPresenceIndicator`` semantics.
  public struct FKPresenceIndicatorView: View {
    public var configuration: FKPresenceIndicatorConfiguration
    public var state: FKPresenceState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
      configuration: FKPresenceIndicatorConfiguration = FKPresenceIndicatorDefaults.configuration,
      state: FKPresenceState = .offline
    ) {
      self.configuration = configuration
      self.state = state
    }

    public var body: some View {
      ZStack {
        if shouldPulse && !reduceMotion {
          Circle()
            .fill(resolvedColor.opacity(0.35))
            .frame(width: configuration.size.diameter, height: configuration.size.diameter)
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
            .animation(
              .easeOut(duration: configuration.pulsePeriod).repeatForever(autoreverses: false),
              value: pulseScale
            )
        }

        Circle()
          .fill(resolvedColor)
          .frame(width: configuration.size.diameter, height: configuration.size.diameter)
          .overlay {
            if configuration.showsBorder {
              Circle()
                .strokeBorder(
                  Color(configuration.borderColor ?? .systemBackground),
                  lineWidth: configuration.borderWidth
                )
            }
          }
      }
      .frame(
        width: configuration.size.diameter + borderOutset * 2,
        height: configuration.size.diameter + borderOutset * 2
      )
      .accessibilityLabel(Text(state.accessibilityLabel))
      .onAppear { syncPulseAnimation() }
      .onChange(of: state) { _ in syncPulseAnimation() }
      .onChange(of: reduceMotion) { _ in syncPulseAnimation() }
    }

    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 0.6

    private var borderOutset: CGFloat {
      configuration.showsBorder ? configuration.borderWidth : 0
    }

    private var shouldPulse: Bool {
      switch state {
      case .online:
        configuration.pulsesWhenOnline
      case .custom(let custom):
        custom.pulses
      default:
        false
      }
    }

    private var resolvedColor: Color {
      switch state {
      case .online:
        Color(configuration.stateColors.online)
      case .offline:
        Color(configuration.stateColors.offline)
      case .busy:
        Color(configuration.stateColors.busy)
      case .away:
        Color(configuration.stateColors.away)
      case .custom(let custom):
        Color(custom.color)
      }
    }

    private func syncPulseAnimation() {
      guard shouldPulse, !reduceMotion else {
        pulseScale = 1
        pulseOpacity = 0.6
        return
      }
      pulseScale = 2.2
      pulseOpacity = 0
    }
  }
#endif
