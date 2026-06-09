import Foundation
import ImageIO

/// Strips or redacts EXIF metadata from encoded image data.
enum FKPhotoEXIFStripper {
  static func stripMetadata(
    from data: Data,
    stripLocation: Bool,
    stripAll: Bool
  ) -> Data? {
    guard stripLocation || stripAll else { return data }

    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let type = CGImageSourceGetType(source),
      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      return data
    }

    var properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]

    if stripAll {
      properties = [:]
    } else if stripLocation {
      properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
    }

    let output = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(output, type, 1, nil)
    else {
      return data
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    guard     CGImageDestinationFinalize(destination) else { return data }
    return output as Data
  }

  static func extractProperties(from data: Data) -> [String: Any]? {
    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
      !properties.isEmpty
    else {
      return nil
    }
    return properties
  }
}
