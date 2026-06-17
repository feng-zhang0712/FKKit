# FKModelMapping

JSON and dictionary mapping utilities for FKCoreKit. Converts API payloads to Swift models with configurable key strategies, loose typing, response envelopes, and FKNetwork integration.

## Directory layout

| Folder | Responsibility |
|--------|----------------|
| `Core/` | `FKModelMapper`, `FKJSONCodec`, `FKModelMappingConfiguration` |
| `Codable/` | Decoding error mapping, property wrappers |
| `Dictionary/` | `FKMap`, `FKDictionaryMapper`, `FKJSONObject`, `FKMappableKnownKeys`, path resolver |
| `Envelope/` | Response envelope processor and network interceptor |
| `Transform/` | Value transforms and registry |
| `Polymorphic/` | Discriminator-based decoding registry |
| `Model/` | Errors, warnings, pagination templates |
| `Support/` | Logging, fixtures, warning collector |
| `Bridge/` | `NetworkError` integration |

## Quick start

```swift
let mapper = FKModelMapper(configuration: .lenientAPI)
let user = try mapper.decode(User.self, from: responseData)

let codec = FKJSONCodec(configuration: .apiDefault)
let client = FKNetworkClient(decoder: codec.makeDecoder())
```

## Envelope APIs

```swift
var config = FKModelMappingConfiguration.lenientAPI
config.envelope = .standard
let mapper = FKModelMapper(configuration: config)
let profile = try mapper.decodeEnvelope(Profile.self, from: data)

let interceptor = FKResponseEnvelopeInterceptor(configuration: .standard)
// Register on FKNetworkConfiguration.responseInterceptors
```

## Manual dictionary mapping

```swift
struct User: FKMappable {
  let id: Int
  let name: String

  init(map: FKMap) throws {
    id = try map.value("user_id", as: Int.self)
    name = try map.value("profile.display_name", as: String.self)
  }
}

let user = try FKDictionaryMapper(configuration: .lenientAPI)
  .decode(User.self, from: payload)
```

## Decision tree

| Need | API |
|------|-----|
| Standard Codable JSON | `FKModelMapper.decode(_:from: Data)` |
| snake_case REST API | `FKModelMappingConfiguration.apiDefault` |
| Loose numbers / empty strings | `.lenientAPI` |
| `{ code, message, data }` envelope | `decodeEnvelope` or `FKResponseEnvelopeInterceptor` |
| Push notification `[String: Any]` | `FKDictionaryMapper` + `FKMappable` |
| Strict unknown-key rejection | `FKMappableKnownKeys` + `.strict` / `unknownKeyStrategy: .fail` |
| Omit null keys in request JSON | `encodeNullStrategy: .omitKey` |
| Inject into FKNetwork | `FKJSONCodec.makeDecoder()` |

## Related modules

- `FKNetwork` — HTTP transport; use `ResponseInterceptor` for envelope unwrap
- `Extension/FKValueParsing` — scalar parsing reused by dictionary mapping
- `Dictionary.fk_decodeJSON` — legacy convenience API with JSON re-serialization

## Requirements

- iOS 15+
- Swift 6
- Zero third-party runtime dependencies

## Design reference

See `docs/FKModelMapping_DESIGN.md`.

## Examples

FKKitExamples hub: **FKCoreKit → ModelMapping** (`FKModelMappingExamplesHubViewController`).

Scenarios cover Codable basics, snake_case, lenient scalars, date formats, property wrappers, strict/lenient modes, dictionary mapping, nested paths, manual `FKMappable`, polymorphic feeds, response envelopes, encoding, Network integration, pagination templates, complex payload mapping, and fixtures.
