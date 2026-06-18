import AVFoundation

/// Applies gallery audio policy on presentation and restores the prior session on dismiss.
@MainActor
final class FKMediaGalleryAudioSessionController {
  private struct SavedState {
    var category: AVAudioSession.Category
    var mode: AVAudioSession.Mode
    var options: AVAudioSession.CategoryOptions
  }

  private var savedState: SavedState?
  private var isActive = false

  func activate(policy: FKMediaGalleryAudioSessionPolicy) {
    guard !isActive else { return }
    let session = AVAudioSession.sharedInstance()
    savedState = SavedState(
      category: session.category,
      mode: session.mode,
      options: session.categoryOptions
    )
    do {
      switch policy {
      case .ambient:
        try session.setCategory(.ambient, mode: .default, options: [])
      case .soloAmbient:
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
        try session.setActive(true)
      case .duckOthers:
        try session.setCategory(.playback, mode: .moviePlayback, options: [.duckOthers])
        try session.setActive(true)
      }
      isActive = true
    } catch {
      savedState = nil
    }
  }

  func deactivate() {
    guard isActive else { return }
    defer {
      isActive = false
      savedState = nil
    }
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false, options: [.notifyOthersOnDeactivation])
      if let savedState {
        try session.setCategory(
          savedState.category,
          mode: savedState.mode,
          options: savedState.options
        )
      }
    } catch { }
  }
}
