import FKUIKit
import Foundation

/// Canonical sample URLs and ``FKAudioItem`` builders for AudioPlayer examples.
enum FKAudioPlayerExampleCatalog {

  // MARK: - Sample streams
  //
  // Royalty-free / permissively licensed demo audio (not production music hosting).
  // Hotel California and similar commercial tracks are intentionally omitted (copyright).

  /// Light instrumental — commonly used in mobile SDK samples.
  static let kalimba = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3")!

  /// Relaxed acoustic guitar (Pixabay license).
  static let acousticGuitar = URL(
    string: "https://cdn.pixabay.com/download/audio/2022/03/24/audio_2dde668d9c.mp3"
  )!

  /// Soft piano ambient (Pixabay license).
  static let softPiano = URL(
    string: "https://cdn.pixabay.com/download/audio/2022/03/10/audio_c8c51a31c0.mp3"
  )!

  static let hlsVOD = URL(
    string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
  )!

  // MARK: - Items

  static func mp3Item(
    id: String,
    url: URL,
    title: String,
    artist: String = "FKKit Demo"
  ) -> FKAudioItem {
    FKAudioItem(
      id: id,
      source: .url(url),
      title: title,
      artist: artist,
      albumTitle: "FKKit Examples"
    )
  }

  static func trackOne(title: String = "Kalimba") -> FKAudioItem {
    mp3Item(id: "audio.mp3.1", url: kalimba, title: title, artist: "Sample — Light Instrumental")
  }

  static func trackTwo(title: String = "Acoustic Breeze") -> FKAudioItem {
    mp3Item(id: "audio.mp3.2", url: acousticGuitar, title: title, artist: "Sample — Acoustic Guitar")
  }

  static func trackThree(title: String = "Soft Piano") -> FKAudioItem {
    mp3Item(id: "audio.mp3.3", url: softPiano, title: title, artist: "Sample — Piano Ambient")
  }

  static func hlsItem(title: String = "Apple Bip-Bop (HLS)") -> FKAudioItem {
    FKAudioItem(
      id: "audio.hls.vod",
      source: .url(hlsVOD),
      title: title,
      artist: "Apple"
    )
  }

  static func demoQueue() -> [FKAudioItem] {
    [
      mp3Item(id: "audio.queue.1", url: kalimba, title: "Queue — Kalimba", artist: "Sample — Light Instrumental"),
      mp3Item(id: "audio.queue.2", url: acousticGuitar, title: "Queue — Acoustic Breeze", artist: "Sample — Acoustic Guitar"),
      mp3Item(id: "audio.queue.3", url: softPiano, title: "Queue — Soft Piano", artist: "Sample — Piano Ambient"),
    ]
  }

  static func podcastItem() -> FKAudioItem {
    FKAudioItem(
      id: "audio.podcast",
      source: .url(kalimba),
      title: "Sample Podcast Episode",
      artist: "FKKit Narrator",
      chapters: [
        FKAudioChapter(title: "Intro", time: 0),
        FKAudioChapter(title: "Main story", time: 30),
        FKAudioChapter(title: "Outro", time: 90),
      ]
    )
  }

  /// Bundled LRC in the example target (see `Support/Resources/sample.lrc`).
  static func bundledLRCURL() -> URL? {
    Bundle.main.url(forResource: "sample", withExtension: "lrc")
  }

  static func itemWithBundledLRC() -> FKAudioItem {
    var item = trackOne(title: "Bundled LRC")
    item.lyricsURL = bundledLRCURL()
    return item
  }

  static func itemWithPlainLyrics() -> FKAudioItem {
    FKAudioItem(
      id: "audio.plain.lyrics",
      source: .url(acousticGuitar),
      title: "Plain lyrics text",
      artist: "FKKit",
      lyricsText: """
      Welcome to FKAudioPlayer demos
      [00:08]Inline timestamp parsing
      [00:16]Plain text fallback also works
      """
    )
  }

  static func insertNextCandidate() -> FKAudioItem {
    mp3Item(id: "audio.insert.next", url: softPiano, title: "Inserted — Soft Piano", artist: "Sample — Piano Ambient")
  }
}
