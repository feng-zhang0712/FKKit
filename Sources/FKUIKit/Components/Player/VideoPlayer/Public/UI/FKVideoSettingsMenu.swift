import UIKit

/// Presents playback speed and quality actions from the video chrome.
@MainActor
public enum FKVideoSettingsMenu {

  public static func present(
    from sourceView: UIView,
    in viewController: UIViewController,
    player: FKVideoPlayer,
    rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
  ) {
    let alert = UIAlertController(title: FKUIKitI18n.string("fkuikit.video.settings.playback_title"), message: nil, preferredStyle: .actionSheet)
    for rate in rates {
      let title = rate == 1 ? FKUIKitI18n.string("fkuikit.video.settings.normal_speed") : String(format: "%.2gx", rate)
      alert.addAction(UIAlertAction(title: title, style: .default) { _ in
        player.rate = rate
      })
    }
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.video.settings.lower_quality"), style: .default) { _ in
      player.selectPeakBitrate(800_000)
    })
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.video.settings.higher_quality"), style: .default) { _ in
      player.selectPeakBitrate(0)
    })

    if !player.embeddedSubtitleTrackNames.isEmpty {
      alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.video.settings.subtitles"), style: .default) { _ in
        presentSubtitleTracks(from: sourceView, in: viewController, player: player)
      })
    }
    if player.embeddedAudioTrackNames.count > 1 {
      alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.video.settings.audio_track"), style: .default) { _ in
        presentAudioTracks(from: sourceView, in: viewController, player: player)
      })
    }

    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.common.cancel"), style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = sourceView
      popover.sourceRect = sourceView.bounds
    }
    viewController.present(alert, animated: true)
  }

  private static func presentSubtitleTracks(
    from sourceView: UIView,
    in viewController: UIViewController,
    player: FKVideoPlayer
  ) {
    let alert = UIAlertController(title: FKUIKitI18n.string("fkuikit.video.settings.subtitles_title"), message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.video.settings.subtitles_off"), style: .default) { _ in
      player.selectEmbeddedSubtitle(named: nil)
    })
    for name in player.embeddedSubtitleTrackNames {
      alert.addAction(UIAlertAction(title: name, style: .default) { _ in
        player.selectEmbeddedSubtitle(named: name)
      })
    }
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.common.cancel"), style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = sourceView
      popover.sourceRect = sourceView.bounds
    }
    viewController.present(alert, animated: true)
  }

  private static func presentAudioTracks(
    from sourceView: UIView,
    in viewController: UIViewController,
    player: FKVideoPlayer
  ) {
    let alert = UIAlertController(title: FKUIKitI18n.string("fkuikit.video.settings.audio_title"), message: nil, preferredStyle: .actionSheet)
    for name in player.embeddedAudioTrackNames {
      alert.addAction(UIAlertAction(title: name, style: .default) { _ in
        player.selectAudioTrack(named: name)
      })
    }
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.common.cancel"), style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = sourceView
      popover.sourceRect = sourceView.bounds
    }
    viewController.present(alert, animated: true)
  }
}
