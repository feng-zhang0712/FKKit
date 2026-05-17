import AVFoundation
import UIKit

/// Simple waveform visualization from an audio asset (Phase 4).
@MainActor
public final class FKAudioWaveformView: UIView {

  private var samples: [Float] = []

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isAccessibilityElement = true
    accessibilityTraits = .updatesFrequently
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func loadWaveform(from asset: AVAsset, sampleCount: Int = 80) async {
    let tracks = asset.tracks(withMediaType: .audio)
    guard let track = tracks.first else { return }
    do {
      let reader = try AVAssetReader(asset: asset)
      let output = AVAssetReaderTrackOutput(
        track: track,
        outputSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVLinearPCMIsFloatKey: true,
          AVLinearPCMBitDepthKey: 32,
          AVLinearPCMIsNonInterleaved: false,
        ]
      )
      reader.add(output)
      reader.startReading()

      var values: [Float] = []
      while let sampleBuffer = output.copyNextSampleBuffer(), values.count < sampleCount * 200 {
        guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        guard let dataPointer else { continue }
        let floatCount = length / MemoryLayout<Float>.size
        dataPointer.withMemoryRebound(to: Float.self, capacity: floatCount) { ptr in
          for index in 0..<floatCount where values.count < sampleCount * 200 {
            values.append(abs(ptr[index]))
          }
        }
      }

      let chunk = max(1, values.count / sampleCount)
      let downsampled = stride(from: 0, to: values.count, by: chunk).map { index -> Float in
        let slice = values[index..<min(index + chunk, values.count)]
        return slice.max() ?? 0
      }
      samples = Array(downsampled.prefix(sampleCount))
      setNeedsDisplay()
    } catch {
      samples = []
      setNeedsDisplay()
    }
  }

  public override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext(), !samples.isEmpty else { return }
    context.setFillColor(UIColor.secondarySystemFill.cgColor)
    context.fill(rect)

    let width = rect.width / CGFloat(samples.count)
    context.setFillColor(UIColor.label.withAlphaComponent(0.75).cgColor)
    for (index, sample) in samples.enumerated() {
      let barHeight = CGFloat(sample) * rect.height
      let x = CGFloat(index) * width
      let y = (rect.height - barHeight) / 2
      context.fill(CGRect(x: x, y: y, width: max(1, width * 0.7), height: barHeight))
    }
  }
}
