import Foundation

public extension FKAudioWaveformLoadResult {
  /// User-facing localized description when loading fails.
  var localizedMessage: String? {
    switch self {
    case .success:
      return nil
    case .noAudioTrack:
      return FKUIKitI18n.string("fkuikit.audio.waveform.no_audio_track")
    case .unreadableAsset:
      return FKUIKitI18n.string("fkuikit.audio.waveform.unreadable_asset")
    case let .readFailed(message):
      return message
    }
  }
}
