import AVFoundation
import Foundation

/// Configures and observes `AVAudioSession` for media playback.
@MainActor
public final class FKMediaAudioSessionManager {

  public static let shared = FKMediaAudioSessionManager()

  private var interruptionHandler: ((Bool) -> Void)?

  public init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Activates the playback category for media.
  public func activatePlaybackCategory(
    mode: AVAudioSession.Mode = .moviePlayback,
    options: AVAudioSession.CategoryOptions = [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP]
  ) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: mode, options: options)
    try session.setActive(true)
  }

  /// Deactivates the audio session.
  public func deactivate() throws {
    try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  /// Called when an audio interruption ends; parameter is whether playback should resume.
  public func setInterruptionHandler(_ handler: @escaping (Bool) -> Void) {
    interruptionHandler = handler
  }

  @objc
  private func handleInterruption(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else { return }

    switch type {
    case .began:
      interruptionHandler?(false)
    case .ended:
      let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      interruptionHandler?(options.contains(.shouldResume))
    @unknown default:
      break
    }
  }
}
