# FKFileManager

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Core Capabilities](#core-capabilities)
  - [File Management](#file-management)
  - [Breakpoint Download](#breakpoint-download)
  - [File Upload](#file-upload)
  - [Cache Management](#cache-management)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [Sandbox Directory Operations](#sandbox-directory-operations)
  - [File ReadWriteDeleteMove](#file-readwritedeletemove)
  - [Breakpoint Download PauseResumeCancel](#breakpoint-download-pauseresumecancel)
  - [File Upload with Progress](#file-upload-with-progress)
  - [Cache Clean and Size Calculation](#cache-clean-and-size-calculation)
  - [Zip CompressDecompress](#zip-compressdecompress)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Background Modes Configuration](#background-modes-configuration)
- [Notes](#notes)
- [License](#license)

## Overview

`FKFileManager` is a native Swift file and transfer module inside `FKCoreKit`.
It provides a unified entry point for sandbox file operations, breakpoint-resumable downloads, multipart uploads, cache utilities, and transfer persistence.

The component is protocol-oriented, singleton-friendly, and supports both `async/await` and closure-based workflows.

## Features

- Pure native implementation using `Foundation`, `FileManager`, and `URLSession`
- Unified sandbox directory access (`home`, `documents`, `caches`, `temporary`)
- File CRUD operations (create, delete, move, copy, rename, exists)
- File metadata query (size, path, extension, MIME type, modified date)
- Codable/text/data/JSON file read-write support
- Recursive file traversal and extension filters
- Breakpoint download with pause/resume/cancel support
- Background download session support (`URLSessionConfiguration.background`)
- Multipart file upload with progress callbacks
- Transfer snapshot persistence for relaunch recovery
- Cache size calculation and one-call cache/temp cleanup
- Disk-space guard API (`ensureSufficientDiskSpace`)
- Native ZIP compress/decompress with zip-slip protection (`Archive`-free, system zlib)
- Background URLSession completion handler registration
- Shared multipart builder (`FKMultipartFormData`) with FKNetwork
- iOS share and preview helper APIs

**Examples:** `Examples/FKCoreKit/FileManager/` — hub lists baseline B1–B8, enhancements E1–E8, and a complete API catalog.

## Core Capabilities

### File Management

- Unified file APIs exposed through `FKFileManager.shared`
- Async-safe file operations designed not to block UI usage flow
- Codable persistence helpers for fast model-to-file storage

### Breakpoint Download

- Download task IDs for lifecycle control
- Pause and resume via resume data
- Snapshot persistence model for transfer state recovery

### File Upload

- Multipart form upload with single or multiple files
- Optional form fields
- Progress and completion callbacks

### Cache Management

- Directory size calculation
- Dedicated cache and temporary cleanup methods
- Disk-space threshold checks before transfer start

## Requirements

- Swift 5.9+
- iOS 13.0+ APIs (ZIP and background recovery require iOS 15+ in practice)
- No third-party dependency

> The repository package platform is iOS 15+ in `Package.swift`. Runtime code avoids APIs above iOS 13 where possible.

## Installation

`FKFileManager` ships as part of `FKCoreKit`.

### Swift Package Manager

```swift
.package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.16.0")
```

Then import:

```swift
import FKCoreKit
```

## Architecture

Module layout follows a clear layered structure:

- `Core/`
  - `FKFileManager.swift` (public entry)
  - `FKFileManagerProtocols.swift` (protocol contracts)
- `Model/`
  - Transfer, file info, traversal, request/response, error models
- `Configuration/`
  - Runtime configuration (`FKFileManagerConfiguration`)
- `Service/`
  - Storage, MIME resolver, ZIP services, transfer persistence
- `Background/`
  - Background URLSession completion handler coordination
- `Download/`
  - URLSession download service
- `Upload/`
  - URLSession multipart upload service
- `Extension/`
  - Convenience APIs and iOS-specific helpers

## Basic Usage

```swift
import FKCoreKit

let manager = FKFileManager.shared
let documents = manager.directoryURL(.documents)
let fileURL = documents.appendingPathComponent("note.txt")

try await manager.writeContent(.text("Hello FKFileManager"), to: fileURL)
let text = try await manager.readText(from: fileURL)
print(text)
```

## Advanced Usage

### Sandbox Directory Operations

```swift
let manager = FKFileManager.shared
let home = manager.directoryURL(.home)
let documents = manager.directoryURL(.documents)
let caches = manager.directoryURL(.caches)
let temporary = manager.directoryURL(.temporary)
```

### File Read/Write/Delete/Move

```swift
struct UserProfile: Codable, Sendable {
  let id: Int
  let name: String
}

let manager = FKFileManager.shared
let docs = manager.directoryURL(.documents)
let source = docs.appendingPathComponent("profile.json")
let target = docs.appendingPathComponent("backup/profile.json")

try await manager.writeModel(UserProfile(id: 1, name: "Frank"), to: source)
let model: UserProfile = try await manager.readModel(UserProfile.self, from: source)

try await manager.createDirectory(at: target.deletingLastPathComponent(), intermediate: true)
try await manager.copyItem(from: source, to: target)
try await manager.removeItem(at: source)

print(model)
```

### Breakpoint Download (Pause/Resume/Cancel)

```swift
let manager = FKFileManager.shared
let destination = manager.directoryURL(.documents)

let request = FKDownloadRequest(
  sourceURL: URL(string: "https://example.com/large-file.zip")!,
  destinationDirectory: destination,
  fileName: "large-file.zip",
  allowsBackground: true
)

let taskID = try await manager.download(
  request,
  progress: { progress in
    print("Download:", progress.progress)
  },
  completion: { result in
    print("Download result:", result)
  }
)

await manager.pauseDownload(taskID: taskID)
await manager.resumeDownload(taskID: taskID)
await manager.cancel(taskID: taskID)
```

### File Upload with Progress

```swift
let manager = FKFileManager.shared
let fileURL = manager.directoryURL(.documents).appendingPathComponent("video.mp4")

var request = URLRequest(url: URL(string: "https://example.com/upload")!)
request.httpMethod = "POST"

let upload = FKUploadRequest(
  urlRequest: request,
  files: [
    FKUploadFile(fieldName: "file", fileURL: fileURL)
  ],
  formFields: ["userId": "1001"]
)

let uploadID = try await manager.upload(
  upload,
  progress: { progress in
    print("Upload:", progress.progress)
  },
  completion: { result in
    print("Upload result:", result)
  }
)

print("Upload task ID:", uploadID)
```

### Cache Clean & Size Calculation

```swift
let manager = FKFileManager.shared
let caches = manager.directoryURL(.caches)

let size = try await manager.directorySize(at: caches)
print("Caches size:", size)

try await manager.clearCaches()
try await manager.clearTemporaryFiles()
```

### Zip Compress/Decompress

```swift
let manager = FKFileManager.shared
let docs = manager.directoryURL(.documents)
let source = docs.appendingPathComponent("folder")
let zip = docs.appendingPathComponent("folder.zip")
let unzipTarget = docs.appendingPathComponent("unzipped")

guard FKFileManager.isZipAvailable else {
  print("ZIP unavailable")
  return
}

try await manager.zipItem(
  at: source,
  to: zip,
  options: FKZipOptions(includesRootDirectoryName: true, compressionMethod: .deflate)
)
try await manager.unzipItem(
  at: zip,
  to: unzipTarget,
  options: FKUnzipOptions(overwritePolicy: .replaceExisting)
)
```

## API Reference

Main entry:

- `FKFileManager.shared`

Directory and file:

- `directoryURL(_:)`
- `createDirectory(at:intermediate:)`
- `removeItem(at:)`
- `moveItem(from:to:)`
- `copyItem(from:to:)`
- `renameItem(at:newName:)`
- `fileInfo(at:)`
- `exists(at:)`
- `enumerateFiles(at:options:)`
- `directorySize(at:)`
- `clearCaches()`
- `clearTemporaryFiles()`

Content serialization:

- `writeContent(_:to:atomically:)`
- `writeModel(_:to:)` (async + closure overload)
- `readData(from:)`
- `readText(from:encoding:)`
- `readModel(_:from:)` (async + closure overload)

Transfer:

- `download(_:progress:completion:)` (async + closure)
- `pauseDownload(taskID:)`
- `resumeDownload(taskID:)`
- `upload(_:progress:completion:)` (async + closure)
- `cancel(taskID:)`
- `cancelAll()`
- `persistedTransfers()`

Utility:

- `ensureSufficientDiskSpace(requiredBytes:)`
- `isImageFile(_:)`
- `zipItem(at:to:)` / `zipItem(at:to:options:)`
- `unzipItem(at:to:)` / `unzipItem(at:to:options:)`
- `FKFileManager.isZipAvailable`
- `registerBackgroundSessionCompletionHandler(_:forSessionWithIdentifier:)`
- iOS-only:
  - `makeShareController(for:)`
  - `makePreviewController(for:)`

## Error Handling

All major operations use `FKFileManagerError`:

- `fileNotFound(path:)`
- `fileAlreadyExists(path:)`
- `invalidURL(_:)`
- `transferFailed(_:)`
- `invalidResponse`
- `insufficientDiskSpace(required:available:)`
- `zipUnavailable`
- `zipCorrupted(archivePath:)`
- `zipEntryPathUnsafe(entry:)`
- `zipOperationFailed(message:)`
- `unknown(_:)`

Example:

```swift
do {
  let info = try await FKFileManager.shared.fileInfo(at: someURL)
  print(info)
} catch let error as FKFileManagerError {
  print("FKFileManager error:", error.localizedDescription)
} catch {
  print("Unexpected error:", error)
}
```

## Best Practices

- Always check and prepare destination directories before transfer-heavy flows.
- Keep strong references to UI objects that consume progress callbacks.
- Use `ensureSufficientDiskSpace()` before large downloads/uploads.
- Store transfer task IDs if you need explicit pause/resume control.
- Use dedicated subfolders under `Documents`/`Caches` for easier cleanup.
- Use background mode only for tasks that must continue when app is not foreground.

## Background Transfer Recovery

To reliably finish background download work when iOS relaunches your app:

1. Open **Target → Signing & Capabilities** and enable **Background Modes** as needed.
2. Configure a unique `backgroundSessionIdentifier` in `FKFileManagerConfiguration`.
3. Forward AppDelegate events to FKFileManager:

```swift
func application(
  _ application: UIApplication,
  handleEventsForBackgroundURLSession identifier: String,
  completionHandler: @escaping () -> Void
) {
  FKFileManager.shared.registerBackgroundSessionCompletionHandler(
    completionHandler,
    forSessionWithIdentifier: identifier
  )
}
```

4. On cold start, call `persistedTransfers()` to rebuild transfer UI state.
5. Re-bind progress/completion handlers when starting new downloads for recovered tasks.
6. Remember that the system may delay or terminate background work; users may need to retry manually.

## Background Modes Configuration

To support background downloads reliably, enable background transfer in your app target:

1. Open **Target -> Signing & Capabilities**.
2. Add **Background Modes** capability.
3. Enable **Background fetch** (optional for surrounding workflows).
4. Enable **Background processing** when needed.
5. Ensure background networking behavior is allowed in your app context.

`FKFileManager` internally uses a background URLSession identifier from `FKFileManagerConfiguration.backgroundSessionIdentifier`.
You can customize it if needed:

```swift
let config = FKFileManagerConfiguration(
  backgroundSessionIdentifier: "com.example.app.filemanager.background"
)
let manager = FKFileManager(configuration: config)
```

## Notes

- Full module design (delivered capabilities, ZIP, background recovery): [`docs/FKFileManager_DESIGN.md`](../../../../docs/FKFileManager_DESIGN.md).
- ZIP uses native zlib (zero third-party); disable via `FKFileManagerConfiguration.isZipEnabled`.
- `clearCaches()` removes **all** contents of the Caches sandbox directory — store durable files under a dedicated Documents subfolder.
- Transfer persistence stores snapshots (`FKPersistedTransfer`) for task restoration metadata.
- iOS helper APIs for share/preview are only compiled on iOS.
- Ensure your upload and download endpoints support resumed transfers if you rely on breakpoint recovery semantics.

## License

This module follows the same license as the FKKit repository.
