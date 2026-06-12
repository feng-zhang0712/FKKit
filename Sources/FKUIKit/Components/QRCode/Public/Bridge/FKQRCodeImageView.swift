#if canImport(SwiftUI)
import FKCoreKit
import SwiftUI
import UIKit

/// SwiftUI view that renders a generated QR code from a string payload.
@MainActor
public struct FKQRCodeImageView: View {
  private let content: String
  private let options: FKQRCodeGenerationOptions

  @State private var image: UIImage?
  @State private var errorMessage: String?

  /// Creates a QR image view for `content`.
  public init(content: String, options: FKQRCodeGenerationOptions = .default) {
    self.content = content
    self.options = options
  }

  public var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .interpolation(.none)
          .resizable()
          .scaledToFit()
      } else if let errorMessage {
        Text(errorMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      } else {
        ProgressView()
      }
    }
    .task(id: ReloadToken(content: content, options: options)) {
      await loadImage()
    }
  }

  private struct ReloadToken: Equatable {
    let content: String
    let options: FKQRCodeGenerationOptions
  }

  private func loadImage() async {
    let content = content
    let options = options
    let result: Result<UIImage, Error> = await Task.detached(priority: .userInitiated) {
      do {
        let image = try FKQRCodeGenerator.makeImage(from: content, options: options)
        return .success(image)
      } catch {
        return .failure(error)
      }
    }.value

    switch result {
    case let .success(image):
      self.image = image
      self.errorMessage = nil
    case let .failure(error):
      self.image = nil
      self.errorMessage = error.localizedDescription
    }
  }
}
#endif
