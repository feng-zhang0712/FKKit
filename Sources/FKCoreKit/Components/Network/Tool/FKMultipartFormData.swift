import Foundation

/// RFC 7578 multipart form builder for file and field uploads.
///
/// MIME types for file parts resolve through ``FKFileMimeResolver`` in the FileManager module.
public struct FKMultipartFormData: Sendable {
  private enum Part: Sendable {
    case field(name: String, value: String)
    case file(name: String, fileName: String, mimeType: String, data: Data)
  }

  private let boundary: String
  private var parts: [Part] = []

  /// Creates a builder with a unique boundary token.
  public init(boundary: String = "FKBoundary-\(UUID().uuidString)") {
    self.boundary = boundary
  }

  /// Appends a text field.
  public mutating func append(_ value: String, name: String) {
    parts.append(.field(name: name, value: value))
  }

  /// Appends a binary file part.
  ///
  /// - Parameters:
  ///   - data: File payload.
  ///   - name: Form field name.
  ///   - fileName: Optional filename; defaults to `upload.bin`.
  ///   - mimeType: Optional MIME type; inferred from filename extension when omitted.
  public mutating func append(
    _ data: Data,
    name: String,
    fileName: String? = nil,
    mimeType: String? = nil
  ) {
    let resolvedName = fileName ?? "upload.bin"
    let ext = (resolvedName as NSString).pathExtension
    let resolvedMIME = mimeType ?? FKFileMimeResolver.mimeType(for: ext)
    parts.append(.file(name: name, fileName: resolvedName, mimeType: resolvedMIME, data: data))
  }

  /// Encodes all parts into a body and matching `Content-Type` header value.
  public func encode() -> (body: Data, contentType: String) {
    var body = Data()
    let lineBreak = "\r\n"

    for part in parts {
      body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
      switch part {
      case let .field(name, value):
        body.append("Content-Disposition: form-data; name=\"\(Self.escape(name))\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append("\(value)\(lineBreak)".data(using: .utf8)!)
      case let .file(name, fileName, mimeType, data):
        body.append(
          "Content-Disposition: form-data; name=\"\(Self.escape(name))\"; filename=\"\(Self.escape(fileName))\"\(lineBreak)"
            .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(data)
        body.append(lineBreak.data(using: .utf8)!)
      }
    }

    body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
    return (body, "multipart/form-data; boundary=\(boundary)")
  }

  private static func escape(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
  }
}
