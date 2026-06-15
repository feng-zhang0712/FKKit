import Foundation
import zlib

/// Native ZIP backend using Foundation and system zlib (no third-party dependency).
struct FKNativeZipService: FKZipOperating {
  static let isSupported = true

  func zipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) async throws {
    try await Task.detached(priority: .utility) {
      try Self.performZipItem(at: sourceURL, to: destinationURL, options: options)
    }.value
  }

  func unzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) async throws {
    try await Task.detached(priority: .utility) {
      try Self.performUnzipItem(at: sourceURL, to: destinationURL, options: options)
    }.value
  }

  private static func performZipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) throws {
    let fileManager = Foundation.FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
      throw FKFileManagerError.fileNotFound(path: sourceURL.path)
    }
    guard fileManager.fileExists(atPath: destinationURL.path) == false else {
      throw FKFileManagerError.fileAlreadyExists(path: destinationURL.path)
    }

    let entries = try collectEntries(sourceURL: sourceURL, isDirectory: isDirectory.boolValue, options: options, fileManager: fileManager)
    let tempURL = destinationURL.appendingPathExtension("zip.tmp")
    defer { try? fileManager.removeItem(at: tempURL) }

    try ensureParentDirectory(for: destinationURL, fileManager: fileManager)
    try FKZipArchiveWriter(fileManager: fileManager).writeArchive(
      entries: entries,
      to: tempURL,
      compressionMethod: options.compressionMethod
    )
    try fileManager.moveItem(at: tempURL, to: destinationURL)
  }

  private static func performUnzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) throws {
    let fileManager = Foundation.FileManager.default
    guard fileManager.fileExists(atPath: sourceURL.path) else {
      throw FKFileManagerError.fileNotFound(path: sourceURL.path)
    }
    if fileManager.fileExists(atPath: destinationURL.path) == false {
      try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
    }

    do {
      try FKZipArchiveReader(fileManager: fileManager).extractArchive(
        at: sourceURL,
        to: destinationURL,
        overwritePolicy: options.overwritePolicy
      )
    } catch let error as FKFileManagerError {
      throw error
    } catch {
      throw FKFileManagerError.zipOperationFailed(message: error.localizedDescription)
    }
  }

  private static func collectEntries(
    sourceURL: URL,
    isDirectory: Bool,
    options: FKZipOptions,
    fileManager: Foundation.FileManager
  ) throws -> [FKZipEntrySource] {
    if isDirectory {
      var entries: [FKZipEntrySource] = []
      let rootName = sourceURL.lastPathComponent
      let prefix = options.includesRootDirectoryName ? rootName + "/" : ""
      if options.includesRootDirectoryName {
        entries.append(.directory(relativePath: rootName + "/"))
      }
      let enumerator = fileManager.enumerator(
        at: sourceURL,
        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
      while let itemURL = enumerator?.nextObject() as? URL {
        let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
        let relative = itemURL.path.replacingOccurrences(of: sourceURL.path + "/", with: "")
        let archivePath = prefix + relative + (values.isDirectory == true ? "/" : "")
        if values.isDirectory == true {
          entries.append(.directory(relativePath: archivePath))
        } else if values.isRegularFile == true {
          entries.append(.file(relativePath: archivePath, fileURL: itemURL))
        }
      }
      return entries
    }

    return [.file(relativePath: sourceURL.lastPathComponent, fileURL: sourceURL)]
  }

  private static func ensureParentDirectory(for url: URL, fileManager: Foundation.FileManager) throws {
    let directory = url.deletingLastPathComponent()
    if fileManager.fileExists(atPath: directory.path) == false {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
  }
}

/// Fallback backend used when ZIP is disabled or unsupported.
struct FKUnavailableZipService: FKZipOperating {
  static let isSupported = false

  func zipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) async throws {
    _ = sourceURL
    _ = destinationURL
    _ = options
    throw FKFileManagerError.zipUnavailable
  }

  func unzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) async throws {
    _ = sourceURL
    _ = destinationURL
    _ = options
    throw FKFileManagerError.zipUnavailable
  }
}

private enum FKZipEntrySource: Sendable {
  case file(relativePath: String, fileURL: URL)
  case directory(relativePath: String)
}

private enum FKZipConstants {
  static let localFileHeaderSignature: UInt32 = 0x0403_4b50
  static let centralDirectorySignature: UInt32 = 0x0201_4b50
  static let endOfCentralDirectorySignature: UInt32 = 0x0605_4b50
  static let compressionStored: UInt16 = 0
  static let compressionDeflate: UInt16 = 8
}

private struct FKZipCentralDirectoryEntry {
  let relativePath: String
  let compressionMethod: UInt16
  let crc32: UInt32
  let compressedSize: UInt32
  let uncompressedSize: UInt32
  let localHeaderOffset: UInt32
  let isDirectory: Bool
}

private struct FKZipArchiveWriter {
  let fileManager: Foundation.FileManager

  func writeArchive(entries: [FKZipEntrySource], to destinationURL: URL, compressionMethod: FKZipCompressionMethod) throws {
    var centralEntries: [FKZipCentralDirectoryEntry] = []
    if fileManager.fileExists(atPath: destinationURL.path) {
      try fileManager.removeItem(at: destinationURL)
    }
    fileManager.createFile(atPath: destinationURL.path, contents: nil)
    let handle = try FileHandle(forWritingTo: destinationURL)
    defer { try? handle.close() }

    var offset: UInt32 = 0
    for entry in entries {
      switch entry {
      case let .directory(relativePath):
        let written = try writeLocalEntry(
          handle: handle,
          relativePath: relativePath,
          fileData: Data(),
          compressionMethod: .none,
          isDirectory: true
        )
        centralEntries.append(
          FKZipCentralDirectoryEntry(
            relativePath: relativePath,
            compressionMethod: FKZipConstants.compressionStored,
            crc32: 0,
            compressedSize: 0,
            uncompressedSize: 0,
            localHeaderOffset: offset,
            isDirectory: true
          )
        )
        offset += written
      case let .file(relativePath, fileURL):
        let fileData = try Data(contentsOf: fileURL)
        let written = try writeLocalEntry(
          handle: handle,
          relativePath: relativePath,
          fileData: fileData,
          compressionMethod: compressionMethod,
          isDirectory: false
        )
        let payload = try compressedPayload(for: fileData, method: compressionMethod)
        centralEntries.append(
          FKZipCentralDirectoryEntry(
            relativePath: relativePath,
            compressionMethod: payload.method,
            crc32: payload.crc32,
            compressedSize: UInt32(payload.data.count),
            uncompressedSize: UInt32(fileData.count),
            localHeaderOffset: offset,
            isDirectory: false
          )
        )
        offset += written
      }
    }

    let centralDirectoryOffset = offset
    var centralDirectorySize: UInt32 = 0
    for entry in centralEntries {
      centralDirectorySize += try writeCentralDirectoryEntry(handle: handle, entry: entry)
    }

    try writeEndOfCentralDirectory(
      handle: handle,
      entryCount: UInt16(centralEntries.count),
      centralDirectorySize: centralDirectorySize,
      centralDirectoryOffset: centralDirectoryOffset
    )
  }

  private struct CompressedPayload {
    let data: Data
    let method: UInt16
    let crc32: UInt32
  }

  private func compressedPayload(for data: Data, method: FKZipCompressionMethod) throws -> CompressedPayload {
    let crc = data.withUnsafeBytes { buffer -> UInt32 in
      guard let base = buffer.baseAddress else { return 0 }
      return UInt32(crc32(0, base.assumingMemoryBound(to: Bytef.self), uInt(data.count)))
    }

    switch method {
    case .none:
      return CompressedPayload(data: data, method: FKZipConstants.compressionStored, crc32: crc)
    case .deflate:
      if data.isEmpty {
        return CompressedPayload(data: data, method: FKZipConstants.compressionStored, crc32: crc)
      }
      let compressed = try deflateRaw(data)
      if compressed.count >= data.count {
        return CompressedPayload(data: data, method: FKZipConstants.compressionStored, crc32: crc)
      }
      return CompressedPayload(data: compressed, method: FKZipConstants.compressionDeflate, crc32: crc)
    }
  }

  private func writeLocalEntry(
    handle: FileHandle,
    relativePath: String,
    fileData: Data,
    compressionMethod: FKZipCompressionMethod,
    isDirectory: Bool
  ) throws -> UInt32 {
    let payload = isDirectory
      ? CompressedPayload(data: Data(), method: FKZipConstants.compressionStored, crc32: 0)
      : try compressedPayload(for: fileData, method: compressionMethod)

    let pathData = Data(relativePath.utf8)
    var header = Data()
    header.appendUInt32(FKZipConstants.localFileHeaderSignature)
    header.appendUInt16(20)
    header.appendUInt16(0)
    header.appendUInt16(payload.method)
    header.appendUInt16(FKZipDOSDate.current.time)
    header.appendUInt16(FKZipDOSDate.current.date)
    header.appendUInt32(payload.crc32)
    header.appendUInt32(UInt32(payload.data.count))
    header.appendUInt32(isDirectory ? 0 : UInt32(fileData.count))
    header.appendUInt16(UInt16(pathData.count))
    header.appendUInt16(0)

    try handle.write(contentsOf: header)
    try handle.write(contentsOf: pathData)
    try handle.write(contentsOf: payload.data)
    return UInt32(header.count + pathData.count + payload.data.count)
  }

  private func writeCentralDirectoryEntry(handle: FileHandle, entry: FKZipCentralDirectoryEntry) throws -> UInt32 {
    let pathData = Data(entry.relativePath.utf8)
    var record = Data()
    record.appendUInt32(FKZipConstants.centralDirectorySignature)
    record.appendUInt16(20)
    record.appendUInt16(20)
    record.appendUInt16(0)
    record.appendUInt16(entry.compressionMethod)
    record.appendUInt16(FKZipDOSDate.current.time)
    record.appendUInt16(FKZipDOSDate.current.date)
    record.appendUInt32(entry.crc32)
    record.appendUInt32(entry.compressedSize)
    record.appendUInt32(entry.uncompressedSize)
    record.appendUInt16(UInt16(pathData.count))
    record.appendUInt16(0)
    record.appendUInt16(0)
    record.appendUInt16(0)
    record.appendUInt16(0)
    record.appendUInt32(0)
    record.appendUInt32(entry.localHeaderOffset)
    let size = UInt32(record.count + pathData.count)
    try handle.write(contentsOf: record)
    try handle.write(contentsOf: pathData)
    return size
  }

  private func writeEndOfCentralDirectory(
    handle: FileHandle,
    entryCount: UInt16,
    centralDirectorySize: UInt32,
    centralDirectoryOffset: UInt32
  ) throws {
    var record = Data()
    record.appendUInt32(FKZipConstants.endOfCentralDirectorySignature)
    record.appendUInt16(0)
    record.appendUInt16(0)
    record.appendUInt16(entryCount)
    record.appendUInt16(entryCount)
    record.appendUInt32(centralDirectorySize)
    record.appendUInt32(centralDirectoryOffset)
    record.appendUInt16(0)
    try handle.write(contentsOf: record)
  }

  private func deflateRaw(_ data: Data) throws -> Data {
    var stream = z_stream()
    var status = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
    guard status == Z_OK else { throw FKFileManagerError.zipOperationFailed(message: "deflate init failed") }
    defer { deflateEnd(&stream) }

    var output = Data()
    let chunkSize = 16_384
    try data.withUnsafeBytes { inputBuffer in
      guard let inputBase = inputBuffer.baseAddress?.assumingMemoryBound(to: Bytef.self) else { return }
      stream.next_in = UnsafeMutablePointer(mutating: inputBase)
      stream.avail_in = uInt(data.count)

      var localOutput = [UInt8](repeating: 0, count: chunkSize)
      repeat {
        stream.next_out = UnsafeMutablePointer(mutating: localOutput)
        stream.avail_out = uInt(chunkSize)
        status = deflate(&stream, Z_FINISH)
        guard status == Z_OK || status == Z_STREAM_END else {
          throw FKFileManagerError.zipOperationFailed(message: "deflate failed")
        }
        let produced = chunkSize - Int(stream.avail_out)
        if produced > 0 {
          output.append(localOutput, count: produced)
        }
      } while status != Z_STREAM_END
    }
    return output
  }
}

private struct FKZipArchiveReader {
  let fileManager: Foundation.FileManager

  func extractArchive(
    at archiveURL: URL,
    to destinationURL: URL,
    overwritePolicy: FKUnzipOptions.OverwritePolicy
  ) throws {
    let data = try Data(contentsOf: archiveURL)
    guard data.count >= 22 else { throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path) }

    let eocdOffset = try findEndOfCentralDirectory(in: data, archivePath: archiveURL.path)
    let entryCount = Int(data.readUInt16(at: eocdOffset + 10))
    let centralDirectorySize = Int(data.readUInt32(at: eocdOffset + 12))
    let centralDirectoryOffset = Int(data.readUInt32(at: eocdOffset + 16))
    guard centralDirectoryOffset + centralDirectorySize <= data.count else {
      throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
    }

    var cursor = centralDirectoryOffset
    for _ in 0 ..< entryCount {
      guard data.readUInt32(at: cursor) == FKZipConstants.centralDirectorySignature else {
        throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
      }

      let compressionMethod = data.readUInt16(at: cursor + 10)
      let crc32Value = data.readUInt32(at: cursor + 16)
      let compressedSize = Int(data.readUInt32(at: cursor + 20))
      let uncompressedSize = Int(data.readUInt32(at: cursor + 24))
      let fileNameLength = Int(data.readUInt16(at: cursor + 28))
      let extraLength = Int(data.readUInt16(at: cursor + 30))
      let commentLength = Int(data.readUInt16(at: cursor + 32))
      let localHeaderOffset = Int(data.readUInt32(at: cursor + 42))
      let nameStart = cursor + 46
      guard nameStart + fileNameLength <= data.count else {
        throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
      }
      let relativePath = String(data: data.subdata(in: nameStart ..< nameStart + fileNameLength), encoding: .utf8) ?? ""
      cursor = nameStart + fileNameLength + extraLength + commentLength

      let targetURL = try resolvedEntryURL(relativePath: relativePath, destinationRoot: destinationURL)
      let isDirectory = relativePath.hasSuffix("/")

      if fileManager.fileExists(atPath: targetURL.path) {
        switch overwritePolicy {
        case .failIfExists:
          throw FKFileManagerError.fileAlreadyExists(path: targetURL.path)
        case .replaceExisting:
          try fileManager.removeItem(at: targetURL)
        }
      }

      if isDirectory {
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
        continue
      }

      guard data.readUInt32(at: localHeaderOffset) == FKZipConstants.localFileHeaderSignature else {
        throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
      }
      let localNameLength = Int(data.readUInt16(at: localHeaderOffset + 26))
      let localExtraLength = Int(data.readUInt16(at: localHeaderOffset + 28))
      let payloadStart = localHeaderOffset + 30 + localNameLength + localExtraLength
      guard payloadStart + compressedSize <= data.count else {
        throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
      }
      let payload = data.subdata(in: payloadStart ..< payloadStart + compressedSize)
      let fileData: Data
      switch compressionMethod {
      case FKZipConstants.compressionStored:
        fileData = payload
      case FKZipConstants.compressionDeflate:
        fileData = try inflateRaw(payload, expectedSize: uncompressedSize)
      default:
        throw FKFileManagerError.zipOperationFailed(message: "Unsupported compression method \(compressionMethod)")
      }

      let computedCRC = fileData.withUnsafeBytes { buffer -> UInt32 in
        guard let base = buffer.baseAddress else { return 0 }
        return UInt32(crc32(0, base.assumingMemoryBound(to: Bytef.self), uInt(fileData.count)))
      }
      if computedCRC != crc32Value || fileData.count != uncompressedSize {
        throw FKFileManagerError.zipCorrupted(archivePath: archiveURL.path)
      }

      try fileManager.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try fileData.write(to: targetURL, options: .atomic)
    }
  }

  private func findEndOfCentralDirectory(in data: Data, archivePath: String) throws -> Int {
    let minimumEOCDSize = 22
    let searchStart = max(0, data.count - 65_536)
    for offset in stride(from: data.count - minimumEOCDSize, through: searchStart, by: -1) {
      if data.readUInt32(at: offset) == FKZipConstants.endOfCentralDirectorySignature {
        return offset
      }
    }
    throw FKFileManagerError.zipCorrupted(archivePath: archivePath)
  }

  private func resolvedEntryURL(relativePath: String, destinationRoot: URL) throws -> URL {
    let normalized = relativePath.replacingOccurrences(of: "\\", with: "/")
    if normalized.hasPrefix("/") || normalized.contains(":") {
      throw FKFileManagerError.zipEntryPathUnsafe(entry: relativePath)
    }

    var resolved = destinationRoot.standardizedFileURL
    for component in normalized.split(separator: "/") {
      if component == ".." {
        throw FKFileManagerError.zipEntryPathUnsafe(entry: relativePath)
      }
      if component == "." { continue }
      resolved = resolved.appendingPathComponent(String(component), isDirectory: false)
    }

    let rootPath = destinationRoot.standardizedFileURL.path
    let resolvedPath = resolved.standardizedFileURL.path
    guard resolvedPath == rootPath || resolvedPath.hasPrefix(rootPath + "/") else {
      throw FKFileManagerError.zipEntryPathUnsafe(entry: relativePath)
    }
    return resolved
  }

  private func inflateRaw(_ data: Data, expectedSize: Int) throws -> Data {
    var stream = z_stream()
    var status = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
    guard status == Z_OK else { throw FKFileManagerError.zipOperationFailed(message: "inflate init failed") }
    defer { inflateEnd(&stream) }

    var output = Data()
    output.reserveCapacity(max(expectedSize, data.count))
    let chunkSize = 16_384

    try data.withUnsafeBytes { inputBuffer in
      guard let inputBase = inputBuffer.baseAddress?.assumingMemoryBound(to: Bytef.self) else { return }
      stream.next_in = UnsafeMutablePointer(mutating: inputBase)
      stream.avail_in = uInt(data.count)

      var localOutput = [UInt8](repeating: 0, count: chunkSize)
      repeat {
        stream.next_out = UnsafeMutablePointer(mutating: localOutput)
        stream.avail_out = uInt(chunkSize)
        status = inflate(&stream, Z_NO_FLUSH)
        guard status == Z_OK || status == Z_STREAM_END else {
          throw FKFileManagerError.zipOperationFailed(message: "inflate failed")
        }
        let produced = chunkSize - Int(stream.avail_out)
        if produced > 0 {
          output.append(localOutput, count: produced)
        }
      } while status != Z_STREAM_END
    }
    return output
  }
}

private enum FKZipDOSDate {
  static var current: (date: UInt16, time: UInt16) {
    let now = Date()
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: now)
    let year = max((components.year ?? 1980) - 1980, 0)
    let month = components.month ?? 1
    let day = components.day ?? 1
    let hour = components.hour ?? 0
    let minute = components.minute ?? 0
    let second = (components.second ?? 0) / 2
    let dosDate = UInt16((year << 9) | (month << 5) | day)
    let dosTime = UInt16((hour << 11) | (minute << 5) | second)
    return (dosDate, dosTime)
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

  func readUInt16(at offset: Int) -> UInt16 {
    subdata(in: offset ..< offset + 2).withUnsafeBytes { $0.load(as: UInt16.self) }.littleEndian
  }

  func readUInt32(at offset: Int) -> UInt32 {
    subdata(in: offset ..< offset + 4).withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
  }
}
