import UIKit

// MARK: - Interface Builder

public extension FKProgressBar {
  /// `0` linear, `1` ring.
  @IBInspectable
  var ibVariant: Int {
    get { configuration.variant.rawValue }
    set { configuration.variant = FKProgressBarVariant(rawValue: newValue) ?? .linear }
  }

  /// `0` horizontal, `1` vertical (linear only).
  @IBInspectable
  var ibAxis: Int {
    get { configuration.axis.rawValue }
    set { configuration.axis = FKProgressBarAxis(rawValue: newValue) ?? .horizontal }
  }

  @IBInspectable
  var ibTrackThickness: CGFloat {
    get { configuration.trackThickness }
    set { configuration.trackThickness = max(0.5, newValue) }
  }

  @IBInspectable
  var ibTrackColor: UIColor {
    get { configuration.trackColor }
    set { configuration.trackColor = newValue }
  }

  @IBInspectable
  var ibProgressColor: UIColor {
    get { configuration.progressColor }
    set { configuration.progressColor = newValue }
  }

  @IBInspectable
  var ibBufferColor: UIColor {
    get { configuration.bufferColor }
    set { configuration.bufferColor = newValue }
  }

  @IBInspectable
  var ibShowsBuffer: Bool {
    get { configuration.showsBuffer }
    set { configuration.showsBuffer = newValue }
  }

  @IBInspectable
  var ibProgress: CGFloat {
    get { progress }
    set { setProgress(newValue, animated: false) }
  }

  @IBInspectable
  var ibBufferProgress: CGFloat {
    get { bufferProgress }
    set { setBufferProgress(newValue, animated: false) }
  }

  @IBInspectable
  var ibIndeterminate: Bool {
    get { isIndeterminate }
    set { isIndeterminate = newValue }
  }

  @IBInspectable
  var ibRingLineWidth: CGFloat {
    get { configuration.ringLineWidth }
    set { configuration.ringLineWidth = max(0.5, newValue) }
  }

  @IBInspectable
  var ibAnimationDuration: CGFloat {
    get { CGFloat(configuration.animationDuration) }
    set { configuration.animationDuration = TimeInterval(max(0, newValue)) }
  }

  @IBInspectable
  var ibSegmentCount: Int {
    get { configuration.segmentCount }
    set { configuration.segmentCount = max(0, newValue) }
  }

  @IBInspectable
  var ibRespectsReducedMotion: Bool {
    get { configuration.respectsReducedMotion }
    set { configuration.respectsReducedMotion = newValue }
  }
}
