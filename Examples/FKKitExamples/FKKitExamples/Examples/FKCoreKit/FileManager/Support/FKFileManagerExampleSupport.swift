import CryptoKit
import FKCoreKit
import Foundation
import zlib

/// Shared helpers for FileManager Examples scenarios.
enum FKFileManagerExampleSupport {
  static let manager = FKFileManager.shared

  static func demoRoot() -> URL {
    manager.directoryURL(.documents).appendingPathComponent("FKFileManagerExamples", isDirectory: true)
  }

  static func scenarioDirectory(_ name: String) -> URL {
    demoRoot().appendingPathComponent(name, isDirectory: true)
  }

  static func sha256Hex(of data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  static func sha256Hex(ofFileAt url: URL) async throws -> String {
    let data = try await manager.readData(from: url)
    return sha256Hex(of: data)
  }

  /// Writes a ZIP archive containing a path-traversal entry for zip-slip demos.
  static func writeZipSlipFixture(to url: URL) throws {
    let entryName = "../zip-slip-escape.txt"
    let payload = Data("zip slip probe".utf8)
    let pathData = Data(entryName.utf8)
    var local = Data()
    local.appendUInt32(0x0403_4b50)
    local.appendUInt16(20)
    local.appendUInt16(0)
    local.appendUInt16(0)
    local.appendUInt16(0)
    local.appendUInt16(0)
    let crc = payload.withUnsafeBytes { buffer -> UInt32 in
      guard let base = buffer.baseAddress else { return 0 }
      return UInt32(crc32(0, base.assumingMemoryBound(to: Bytef.self), uInt(payload.count)))
    }
    local.appendUInt32(crc)
    local.appendUInt32(UInt32(payload.count))
    local.appendUInt32(UInt32(payload.count))
    local.appendUInt16(UInt16(pathData.count))
    local.appendUInt16(0)
    local.append(pathData)
    local.append(payload)

    var central = Data()
    central.appendUInt32(0x0201_4b50)
    central.appendUInt16(20)
    central.appendUInt16(20)
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt32(crc)
    central.appendUInt32(UInt32(payload.count))
    central.appendUInt32(UInt32(payload.count))
    central.appendUInt16(UInt16(pathData.count))
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt16(0)
    central.appendUInt32(0)
    central.appendUInt32(0)
    central.append(pathData)

    var eocd = Data()
    eocd.appendUInt32(0x0605_4b50)
    eocd.appendUInt16(0)
    eocd.appendUInt16(0)
    eocd.appendUInt16(1)
    eocd.appendUInt16(1)
    eocd.appendUInt32(UInt32(central.count))
    eocd.appendUInt32(UInt32(local.count))
    eocd.appendUInt16(0)

    var archive = local
    archive.append(central)
    archive.append(eocd)
    try archive.write(to: url, options: .atomic)
  }
}

private extension Data {
  mutating func appendUInt16(_ value: UInt16) {
    var little = value.littleEndian
    append(Data(bytes: &little, count: 2))
  }

  mutating func appendUInt32(_ value: UInt32) {
    var little = value.littleEndian
    append(Data(bytes: &little, count: 4))
  }
}
