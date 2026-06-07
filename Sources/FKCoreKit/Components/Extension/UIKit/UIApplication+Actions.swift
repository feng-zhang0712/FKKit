import AudioToolbox
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

public extension UIApplication {
  /// Opens the App Store page for the given app identifier.
  static func fk_openAppStore(appID: String) {
    fk_openURLString("itms-apps://itunes.apple.com/app/id\(appID)")
  }

  /// Starts a phone call when supported.
  static func fk_openPhoneCall(_ phoneNumber: String) {
    fk_openURLString("tel://\(phoneNumber)")
  }

  /// Opens the Messages compose URL for a phone number.
  static func fk_openSMS(_ phoneNumber: String) {
    fk_openURLString("sms://\(phoneNumber)")
  }

  /// Opens a mail compose URL.
  static func fk_openEmail(address: String, subject: String? = nil) {
    var text = "mailto:\(address)"
    if let subject, !subject.isEmpty {
      text += "?subject=\(subject.fk_urlEncoded)"
    }
    fk_openURLString(text)
  }

  /// Triggers the system vibration alert.
  static func fk_vibrate() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  /// Plays a bundled sound file from the main bundle.
  static func fk_playBundledSound(named fileName: String, fileExtension: String) {
    #if canImport(AVFoundation)
    guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else { return }
    let player = try? AVAudioPlayer(contentsOf: url)
    player?.prepareToPlay()
    player?.play()
    FKBundledSoundPlayerStore.shared.set(player)
    #endif
  }

  private static func fk_openURLString(_ string: String) {
    #if canImport(UIKit)
    guard let url = URL(string: string) else { return }
    Task { @MainActor in
      shared.open(url, options: [:], completionHandler: nil)
    }
    #endif
  }
}

#if canImport(AVFoundation)
private final class FKBundledSoundPlayerStore: @unchecked Sendable {
  static let shared = FKBundledSoundPlayerStore()
  private let lock = NSLock()
  private var player: AVAudioPlayer?

  func set(_ player: AVAudioPlayer?) {
    lock.lock()
    defer { lock.unlock() }
    self.player = player
  }
}
#endif
