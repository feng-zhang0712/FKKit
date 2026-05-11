import FKCoreKit
import Security
import UIKit

/// Hands-on catalog of **every** major `FKSecurity` surface: async/await, closure overloads,
/// `FKSecurity` convenience shortcuts, and edge cases (verify failures, Keychain lifecycle).
/// All user-visible copy is English-only.
final class FKSecurityExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let logView = UITextView()

  private let security = FKSecurity.shared

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSecurity"
    view.backgroundColor = .systemBackground
    buildLayout()
    buildSections()
    appendLog("FKSecurity playground — tap sections below; log stays fixed at the bottom.")
  }

  // MARK: - Layout (matches FKAsync / Permissions / Network examples)

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func buildSections() {
    addSectionHeading("Hash — async (FKHashing)")
    addActionButton("String + Data — MD5, SHA1, SHA256, SHA512") { [weak self] in self?.runHashAsyncAllAlgorithms() }
    addActionButton("Streaming file hash (SHA256)") { [weak self] in self?.runHashFileAsync() }

    addSectionHeading("Hash — completion (FKHashing)")
    addActionButton("hashString + hashData + hashFile (completion)") { [weak self] in self?.runHashCompletions() }

    addSectionHeading("Hash — FKSecurity convenience")
    addActionButton("security.hash(algorithm:, string:) async") { [weak self] in self?.runHashConvenienceAsync() }
    addActionButton("security.hash(algorithm:, string:, completion:)") { [weak self] in self?.runHashConvenienceCompletion() }

    addSectionHeading("AES — async (FKAESCrypting)")
    addActionButton("CBC — string + Data roundtrip + generateKey/generateIV") { [weak self] in self?.runAESCBCAsync() }
    addActionButton("ECB — Data (IV ignored by design)") { [weak self] in self?.runAESECBAsync() }
    addActionButton("encryptFile / decryptFile (streaming)") { [weak self] in self?.runAESFileAsync() }

    addSectionHeading("AES — closure extensions")
    addActionButton("encrypt → decrypt (Data, nested completions)") { [weak self] in self?.runAESDataClosureChain() }
    addActionButton("encryptFile → decryptFile (completion)") { [weak self] in self?.runAESFileClosure() }

    addSectionHeading("AES — FKSecurity convenience")
    addActionButton("aesEncrypt / aesDecrypt (async)") { [weak self] in self?.runAESConvenienceAsync() }
    addActionButton("aesEncrypt / aesDecrypt (completion)") { [weak self] in self?.runAESConvenienceCompletion() }

    addSectionHeading("RSA — async (FKRSACrypting)")
    addActionButton("Key pair (memory) — OAEP + PKCS1 encrypt/decrypt") { [weak self] in self?.runRSAEncryptionsAsync() }
    addActionButton("Sign — SHA256 + SHA512, verify + tamper (expect false)") { [weak self] in self?.runRSASignVerifyAsync() }
    addActionButton("publicKey(from:) + SPKI/PKCS8 export/import + raw PKCS#1 import") { [weak self] in self?.runRSAImportExportAsync() }

    addSectionHeading("RSA — closure extensions")
    addActionButton("generateKeyPair → encrypt → decrypt → sign → verify (nested)") { [weak self] in self?.runRSAClosureChain() }

    addSectionHeading("RSA — FKSecurity convenience")
    addActionButton("rsaEncrypt / rsaDecrypt (async + completion)") { [weak self] in self?.runRSAFKSecurityConvenience() }

    addSectionHeading("Encoding (FKSecurityCoding)")
    addActionButton("Base64, HEX (lower/upper), URL encode/decode") { [weak self] in self?.runEncodingDemo() }

    addSectionHeading("HMAC & parameter signing (FKSecuritySigning)")
    addActionButton("hmac(Data) + hmacHex — SHA256 / SHA512") { [weak self] in self?.runHMACAsync() }
    addActionButton("hmac(…, completion:) — raw MAC bytes") { [weak self] in self?.runHMACCompletion() }
    addActionButton("signParameters [String: Any] — nested JSON + verifyParameters") { [weak self] in self?.runSignParametersAny() }
    addActionButton("signParameters [String: String] — Sendable overload + wrong signature") { [weak self] in self?.runSignParametersString() }
    addActionButton("signParameters [String: String] (completion)") { [weak self] in self?.runSignParametersStringCompletion() }
    addActionButton("FKSecurity.hmacSignParams (async)") { [weak self] in self?.runHmacSignParamsConvenience() }

    addSectionHeading("Random & Keychain")
    addActionButton("randomBytes + randomString (async)") { [weak self] in self?.runRandomAsync() }
    addActionButton("randomBytes (completion) + secureWipeFile (completion)") { [weak self] in self?.runUtilsClosures() }
    addActionButton("Keychain — setKey, key, exists, removeKey") { [weak self] in self?.runKeychainLifecycle() }

    addSectionHeading("Masking (synchronous)")
    addActionButton("maskPhone, maskIDCard, maskEmail") { [weak self] in self?.runMasking() }

    addSectionHeading("Wipe, debugger heuristics, executable hash")
    addActionButton("secureWipe(Data) + secureWipeFile(async) + isDebuggerAttached + hasSuspiciousEnvironment") { [weak self] in
      self?.runWipeAndEnvironment()
    }
    addActionButton("snapshotExecutableHash + verifyExecutableHashSnapshot") { [weak self] in self?.runExecutableHash() }

    addSectionHeading("Controls")
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  private func addSectionHeading(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    contentStack.addArrangedSubview(label)
    contentStack.setCustomSpacing(12, after: label)
  }

  private func addActionButton(_ title: String, handler: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    contentStack.addArrangedSubview(button)
  }

  // MARK: - Hash

  private func runHashAsyncAllAlgorithms() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let text = "Hello FKSecurity"
        let data = Data(text.utf8)
        let md5 = try await security.hash.hashString(text, algorithm: .md5)
        let sha1 = try await security.hash.hashData(data, algorithm: .sha1)
        let sha256 = try await security.hash.hashString(text, algorithm: .sha256)
        let sha512 = try await security.hash.hashData(data, algorithm: .sha512)
        appendLog("MD5: \(md5)")
        appendLog("SHA1: \(sha1)")
        appendLog("SHA256: \(sha256)")
        appendLog("SHA512: \(sha512)")
      } catch {
        appendLog("hash async error: \(error.localizedDescription)")
      }
    }
  }

  private func runHashFileAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = try makeDemoFile(name: "hash-stream.txt", content: "Streamed hash demo payload.")
        let digest = try await security.hash.hashFile(at: url, algorithm: .sha256)
        appendLog("File SHA256: \(digest)")
        appendLog("Path: \(url.path)")
      } catch {
        appendLog("hashFile error: \(error.localizedDescription)")
      }
    }
  }

  private func runHashCompletions() {
    let text = "Completion-style hashing"
    let data = Data(text.utf8)
    appendLog("[hash] starting completion APIs…")
    security.hash.hashString(text, algorithm: .sha256) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(hex):
          self.appendLog("hashString completion SHA256: \(hex)")
        case let .failure(err):
          self.appendLog("hashString completion error: \(err.localizedDescription)")
        }
      }
    }
    security.hash.hashData(data, algorithm: .md5) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(hex):
          self.appendLog("hashData completion MD5: \(hex)")
        case let .failure(err):
          self.appendLog("hashData completion error: \(err.localizedDescription)")
        }
      }
    }
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = try self.makeDemoFile(name: "hash-completion.txt", content: "file")
        self.security.hash.hashFile(at: url, algorithm: .sha512) { result in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch result {
            case let .success(hex):
              self.appendLog("hashFile completion SHA512: \(hex)")
            case let .failure(err):
              self.appendLog("hashFile completion error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        self.appendLog("hashFile setup error: \(error.localizedDescription)")
      }
    }
  }

  private func runHashConvenienceAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let h = try await security.hash(.sha256, string: "FKSecurity.hash shorthand")
        appendLog("FKSecurity.hash(.sha256, string:): \(h)")
      } catch {
        appendLog("convenience hash error: \(error.localizedDescription)")
      }
    }
  }

  private func runHashConvenienceCompletion() {
    security.hash(.md5, string: "closure overload") { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(hex):
          self.appendLog("FKSecurity.hash(…, completion:) MD5: \(hex)")
        case let .failure(err):
          self.appendLog("FKSecurity.hash completion error: \(err.localizedDescription)")
        }
      }
    }
  }

  // MARK: - AES

  private func runAESCBCAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await security.aes.generateKey(length: 32)
        let iv = try await security.aes.generateIV()
        let plaintext = "AES-CBC + PKCS7 via CommonCrypto."
        let b64 = try await security.aes.encryptString(plaintext, using: key, iv: iv, mode: .cbc)
        let roundtrip = try await security.aes.decryptString(b64, using: key, iv: iv, mode: .cbc)
        let data = Data([0x01, 0x02, 0x03, 0xAA])
        let enc = try await security.aes.encrypt(data, using: key, iv: iv, mode: .cbc)
        let dec = try await security.aes.decrypt(enc, using: key, iv: iv, mode: .cbc)
        appendLog("CBC string OK: \(roundtrip == plaintext)")
        appendLog("CBC Data OK: \(dec == data)")
      } catch {
        appendLog("AES CBC error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESECBAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await security.aes.generateKey(length: 16)
        let junkIV = try await security.aes.generateIV()
        let plain = Data("ECB ignores IV".utf8)
        let enc = try await security.aes.encrypt(plain, using: key, iv: junkIV, mode: .ecb)
        let dec = try await security.aes.decrypt(enc, using: key, iv: nil, mode: .ecb)
        appendLog("ECB roundtrip: \(dec == plain)")
      } catch {
        appendLog("AES ECB error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESFileAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let input = try makeDemoFile(name: "aes-in.txt", content: "File encryption demo — FKSecurity.")
        let outputEnc = input.deletingLastPathComponent().appendingPathComponent("aes-out.enc")
        let outputDec = input.deletingLastPathComponent().appendingPathComponent("aes-out.txt")
        let key = try await security.aes.generateKey(length: 32)
        let iv = try await security.aes.generateIV()
        try await security.aes.encryptFile(at: input, to: outputEnc, using: key, iv: iv, mode: .cbc)
        try await security.aes.decryptFile(at: outputEnc, to: outputDec, using: key, iv: iv, mode: .cbc)
        let restored = try String(contentsOf: outputDec, encoding: .utf8)
        appendLog("AES file pipeline OK: \(restored.hasPrefix("File encryption"))")
      } catch {
        appendLog("AES file error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESDataClosureChain() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await security.aes.generateKey(length: 16)
        let iv = try await security.aes.generateIV()
        let plain = Data("closure chain".utf8)
        security.aes.encrypt(plain, using: key, iv: iv, mode: .cbc) { encResult in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch encResult {
            case let .success(cipher):
              self.appendLog("AES closure encrypt bytes: \(cipher.count)")
              self.security.aes.decrypt(cipher, using: key, iv: iv, mode: .cbc) { decResult in
                Task { @MainActor [weak self] in
                  guard let self else { return }
                  switch decResult {
                  case let .success(out):
                    self.appendLog("AES closure decrypt OK: \(out == plain)")
                  case let .failure(err):
                    self.appendLog("AES closure decrypt error: \(err.localizedDescription)")
                  }
                }
              }
            case let .failure(err):
              self.appendLog("AES closure encrypt error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        appendLog("AES closure setup error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESFileClosure() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let input = try makeDemoFile(name: "aes-closure-in.txt", content: "closure file")
        let encURL = input.deletingLastPathComponent().appendingPathComponent("aes-closure.enc")
        let decURL = input.deletingLastPathComponent().appendingPathComponent("aes-closure-out.txt")
        let key = try await security.aes.generateKey(length: 32)
        let iv = try await security.aes.generateIV()
        security.aes.encryptFile(at: input, to: encURL, using: key, iv: iv, mode: .cbc) { [weak self] encRes in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch encRes {
            case .success:
              self.appendLog("encryptFile completion OK")
              self.security.aes.decryptFile(at: encURL, to: decURL, using: key, iv: iv, mode: .cbc) { decRes in
                Task { @MainActor [weak self] in
                  guard let self else { return }
                  switch decRes {
                  case .success:
                    self.appendLog("decryptFile completion OK")
                  case let .failure(err):
                    self.appendLog("decryptFile completion error: \(err.localizedDescription)")
                  }
                }
              }
            case let .failure(err):
              self.appendLog("encryptFile completion error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        appendLog("AES file closure setup error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESConvenienceAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await security.aes.generateKey(length: 32)
        let iv = try await security.aes.generateIV()
        let enc = try await security.aesEncrypt("Convenience API", key: key, iv: iv, mode: .cbc)
        let dec = try await security.aesDecrypt(enc, key: key, iv: iv, mode: .cbc)
        appendLog("FKSecurity.aesEncrypt/Decrypt: \(dec)")
      } catch {
        appendLog("AES convenience error: \(error.localizedDescription)")
      }
    }
  }

  private func runAESConvenienceCompletion() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await security.aes.generateKey(length: 32)
        let iv = try await security.aes.generateIV()
        security.aesEncrypt("completion convenience", key: key, iv: iv, mode: .cbc) { encRes in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch encRes {
            case let .success(b64):
              self.security.aesDecrypt(b64, key: key, iv: iv, mode: .cbc) { decRes in
                Task { @MainActor [weak self] in
                  guard let self else { return }
                  switch decRes {
                  case let .success(plain):
                    self.appendLog("AES convenience completion plain: \(plain)")
                  case let .failure(err):
                    self.appendLog("aesDecrypt completion error: \(err.localizedDescription)")
                  }
                }
              }
            case let .failure(err):
              self.appendLog("aesEncrypt completion error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        appendLog("AES convenience setup error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - RSA

  private func runRSAEncryptionsAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let tag = "com.fkkit.examples.rsa.enc.\(UUID().uuidString)"
        let pair = try await security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false)
        let msg = Data("hybrid payload".utf8)
        let oaep = try await security.rsa.encrypt(msg, publicKey: pair.publicKey, algorithm: .oaepSHA256)
        let oaepPlain = try await security.rsa.decrypt(oaep, privateKey: pair.privateKey, algorithm: .oaepSHA256)
        let pkcs = try await security.rsa.encrypt(msg, publicKey: pair.publicKey, algorithm: .pkcs1)
        let pkcsPlain = try await security.rsa.decrypt(pkcs, privateKey: pair.privateKey, algorithm: .pkcs1)
        appendLog("OAEP roundtrip: \(oaepPlain == msg)")
        appendLog("PKCS#1 v1.5 roundtrip: \(pkcsPlain == msg)")
      } catch {
        appendLog("RSA encrypt async error: \(error.localizedDescription)")
      }
    }
  }

  private func runRSASignVerifyAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let tag = "com.fkkit.examples.rsa.sign.\(UUID().uuidString)"
        let pair = try await security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false)
        let message = Data("signed payload".utf8)
        let sig256 = try await security.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA256)
        let ok256 = try await security.rsa.verify(sig256, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA256)
        let sig512 = try await security.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA512)
        let ok512 = try await security.rsa.verify(sig512, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA512)
        let tampered = Data("tampered payload".utf8)
        let bad = try await security.rsa.verify(sig256, data: tampered, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA256)
        appendLog("Verify OK (SHA256): \(ok256), OK (SHA512): \(ok512)")
        appendLog("Verify with wrong message returns false: \(bad == false)")
      } catch {
        appendLog("RSA sign async error: \(error.localizedDescription)")
      }
    }
  }

  private func runRSAImportExportAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let tag = "com.fkkit.examples.rsa.imp.\(UUID().uuidString)"
        let pair = try await security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false)
        let derivedPub = try await security.rsa.publicKey(from: pair.privateKey)
        let spki = try await security.rsa.exportPublicKeySPKIDER(pair.publicKey)
        let pkcs8 = try await security.rsa.exportPrivateKeyPKCS8DER(pair.privateKey)
        _ = try await security.rsa.importPublicKey(fromDER: spki, isSPKI: true)
        _ = try await security.rsa.importPrivateKey(fromDER: pkcs8, isPKCS8: true)
        appendLog("publicKey(from:) == pair.publicKey: \(CFEqual(derivedPub, pair.publicKey))")
        guard let rawPub = SecKeyCopyExternalRepresentation(pair.publicKey, nil) as Data? else {
          appendLog("SecKeyCopyExternalRepresentation(public) nil")
          return
        }
        guard let rawPriv = SecKeyCopyExternalRepresentation(pair.privateKey, nil) as Data? else {
          appendLog("SecKeyCopyExternalRepresentation(private) nil")
          return
        }
        _ = try await security.rsa.importPublicKey(fromDER: rawPub, isSPKI: false)
        _ = try await security.rsa.importPrivateKey(fromDER: rawPriv, isPKCS8: false)
        appendLog("Raw PKCS#1 import OK. SPKI=\(spki.count)b PKCS8=\(pkcs8.count)b")
      } catch {
        appendLog("RSA import/export error: \(error.localizedDescription)")
      }
    }
  }

  private func runRSAClosureChain() {
    let tag = "com.fkkit.examples.rsa.cb.\(UUID().uuidString)"
    security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false) { [weak self] pairResult in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch pairResult {
        case let .success(pair):
          let message = Data("rsa nested callbacks".utf8)
          self.security.rsa.encrypt(message, publicKey: pair.publicKey, algorithm: .oaepSHA256) { encRes in
            Task { @MainActor [weak self] in
              guard let self else { return }
              switch encRes {
              case let .success(cipher):
                self.security.rsa.decrypt(cipher, privateKey: pair.privateKey, algorithm: .oaepSHA256) { decRes in
                  Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch decRes {
                    case let .success(plain):
                      self.appendLog("RSA closure decrypt: \(plain == message)")
                      self.security.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA256) { sigRes in
                        Task { @MainActor [weak self] in
                          guard let self else { return }
                          switch sigRes {
                          case let .success(sig):
                            self.security.rsa.verify(sig, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA256) { verRes in
                              Task { @MainActor [weak self] in
                                guard let self else { return }
                                switch verRes {
                                case let .success(ok):
                                  self.appendLog("RSA closure verify: \(ok)")
                                case let .failure(err):
                                  self.appendLog("RSA closure verify error: \(err.localizedDescription)")
                                }
                              }
                            }
                          case let .failure(err):
                            self.appendLog("RSA closure sign error: \(err.localizedDescription)")
                          }
                        }
                      }
                    case let .failure(err):
                      self.appendLog("RSA closure decrypt error: \(err.localizedDescription)")
                    }
                  }
                }
              case let .failure(err):
                self.appendLog("RSA closure encrypt error: \(err.localizedDescription)")
              }
            }
          }
        case let .failure(err):
          self.appendLog("RSA closure keygen error: \(err.localizedDescription)")
        }
      }
    }
  }

  private func runRSAFKSecurityConvenience() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let tag = "com.fkkit.examples.rsa.fk.\(UUID().uuidString)"
        let pair = try await security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false)
        let blob = Data("fk convenience".utf8)
        let enc = try await security.rsaEncrypt(blob, publicKey: pair.publicKey, algorithm: .pkcs1)
        let dec = try await security.rsaDecrypt(enc, privateKey: pair.privateKey, algorithm: .pkcs1)
        appendLog("FKSecurity rsaEncrypt/Decrypt async: \(dec == blob)")
        security.rsaEncrypt(blob, publicKey: pair.publicKey, algorithm: .pkcs1) { res in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch res {
            case let .success(cipher):
              self.security.rsaDecrypt(cipher, privateKey: pair.privateKey, algorithm: .pkcs1) { decRes in
                Task { @MainActor [weak self] in
                  guard let self else { return }
                  switch decRes {
                  case let .success(out):
                    self.appendLog("FKSecurity rsa closure roundtrip: \(out == blob)")
                  case let .failure(err):
                    self.appendLog("rsaDecrypt completion error: \(err.localizedDescription)")
                  }
                }
              }
            case let .failure(err):
              self.appendLog("rsaEncrypt completion error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        appendLog("RSA FKSecurity convenience error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Encoding

  private func runEncodingDemo() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let coder = security.code
        let bytes = Data([0x01, 0xAB, 0xFF])
        let b64 = coder.base64Encode(bytes)
        let decB64 = try coder.base64Decode(b64)
        let hexLower = coder.hexString(from: bytes, uppercase: false)
        let hexUpper = coder.hexString(from: bytes, uppercase: true)
        let decHex = try coder.data(fromHex: hexLower)
        let raw = "q=hello world&emoji=🙂"
        appendLog("Base64 roundtrip: \(decB64 == bytes)")
        appendLog("HEX lower/upper: \(hexLower) / \(hexUpper)")
        appendLog("HEX decode: \(decHex == bytes)")
        appendLog("URL: \(coder.urlDecode(coder.urlEncode(raw)))")
      } catch {
        appendLog("Encoding error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - HMAC & signing

  private func runHMACAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let payload = Data("payload".utf8)
        let key = Data("secret".utf8)
        let raw256 = try await security.sign.hmac(payload, key: key, algorithm: .sha256)
        let hex256 = try await security.sign.hmacHex(payload, key: key, algorithm: .sha256)
        let hex512 = try await security.sign.hmacHex(payload, key: key, algorithm: .sha512)
        appendLog("HMAC-SHA256 raw bytes: \(raw256.count), hex: \(hex256)")
        appendLog("HMAC-SHA512 hex: \(hex512)")
      } catch {
        appendLog("HMAC async error: \(error.localizedDescription)")
      }
    }
  }

  private func runHMACCompletion() {
    let payload = Data("hmac completion".utf8)
    let key = Data("key".utf8)
    security.sign.hmac(payload, key: key, algorithm: .sha512) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(mac):
          self.appendLog("hmac completion byte count: \(mac.count)")
        case let .failure(err):
          self.appendLog("hmac completion error: \(err.localizedDescription)")
        }
      }
    }
  }

  private func runSignParametersAny() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let params: [String: Any] = [
          "userId": 1001,
          "roles": ["read", "write"],
          "meta": ["region": "EU"],
        ]
        let secret = "shared-secret"
        let sig = try await security.sign.signParameters(params, secret: secret, algorithm: .sha256)
        let ok = try await security.sign.verifyParameters(params, secret: secret, signatureHex: sig, algorithm: .sha256)
        let bad = try await security.sign.verifyParameters(params, secret: secret, signatureHex: "deadbeef", algorithm: .sha256)
        appendLog("signParameters [Any] verify OK: \(ok), bogus hex: \(bad)")
      } catch {
        appendLog("signParameters [Any] error: \(error.localizedDescription)")
      }
    }
  }

  private func runSignParametersString() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let params: [String: String] = [
          "a": "1",
          "b": "2",
          "z": "last",
        ]
        let sig = try await security.sign.signParameters(params, secret: "s", algorithm: .sha256)
        let ok = try await security.sign.verifyParameters(params, secret: "s", signatureHex: sig, algorithm: .sha256)
        let wrongSecret = try await security.sign.verifyParameters(params, secret: "other", signatureHex: sig, algorithm: .sha256)
        appendLog("Sendable [String:String] verify: \(ok), wrong secret: \(wrongSecret)")
      } catch {
        appendLog("signParameters String error: \(error.localizedDescription)")
      }
    }
  }

  private func runSignParametersStringCompletion() {
    let params = ["foo": "bar", "n": "42"]
    security.sign.signParameters(params, secret: "sc", algorithm: .sha256) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(hex):
          self.appendLog("signParameters completion hex: \(hex.prefix(24))…")
        case let .failure(err):
          self.appendLog("signParameters completion error: \(err.localizedDescription)")
        }
      }
    }
  }

  private func runHmacSignParamsConvenience() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let p: [String: Any] = ["k": "v", "t": 1]
        let sig = try await security.hmacSignParams(p, secret: "sec", algorithm: .sha256)
        appendLog("FKSecurity.hmacSignParams: \(sig.prefix(20))…")
      } catch {
        appendLog("hmacSignParams error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Random, Keychain, utils closures

  private func runRandomAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let s = try await security.utils.randomString(length: 12, alphabet: "abc123")
        let b = try await security.utils.randomBytes(count: 16)
        appendLog("randomString: \(s)")
        appendLog("randomBytes length: \(b.count)")
      } catch {
        appendLog("random async error: \(error.localizedDescription)")
      }
    }
  }

  private func runUtilsClosures() {
    security.utils.randomBytes(count: 8) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        switch result {
        case let .success(data):
          self.appendLog("randomBytes completion: \(data.count) bytes")
        case let .failure(err):
          self.appendLog("randomBytes completion error: \(err.localizedDescription)")
        }
      }
    }
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = try self.makeDemoFile(name: "wipe-closure.txt", content: "x")
        self.security.utils.secureWipeFile(at: url, passes: 1) { wipeResult in
          Task { @MainActor [weak self] in
            guard let self else { return }
            switch wipeResult {
            case .success:
              self.appendLog("secureWipeFile completion finished")
            case let .failure(err):
              self.appendLog("secureWipeFile completion error: \(err.localizedDescription)")
            }
          }
        }
      } catch {
        self.appendLog("wipe closure setup error: \(error.localizedDescription)")
      }
    }
  }

  private func runKeychainLifecycle() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let account = "fksecurity.demo.key.\(UUID().uuidString.prefix(8))"
        let material = try await security.aes.generateKey(length: 32)
        let existsBefore = security.keys.exists(key: account)
        try security.keys.setKey(material, forKey: account, accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        let loaded = try security.keys.key(forKey: account)
        let existsAfter = security.keys.exists(key: account)
        try security.keys.removeKey(forKey: account)
        let existsRemoved = security.keys.exists(key: account)
        appendLog("Keychain exists before/after/remove: \(existsBefore) → \(existsAfter) → \(existsRemoved)")
        appendLog("Keychain roundtrip bytes match: \(loaded == material)")
      } catch {
        appendLog("Keychain error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Masking & environment

  private func runMasking() {
    appendLog("maskPhone: \(security.utils.maskPhone("+1 202 555 0132"))")
    appendLog("maskIDCard: \(security.utils.maskIDCard("110101199001011234"))")
    appendLog("maskEmail: \(security.utils.maskEmail("alice.smith@example.com"))")
  }

  private func runWipeAndEnvironment() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        var secret = Data("erase-me".utf8)
        security.utils.secureWipe(&secret)
        appendLog("secureWipe empty: \(secret.isEmpty)")
        let url = try makeDemoFile(name: "secure-wipe.txt", content: "overwrite then delete")
        try await security.utils.secureWipeFile(at: url, passes: 1)
        appendLog("secureWipeFile removed file: \(!FileManager.default.fileExists(atPath: url.path))")
        appendLog("isDebuggerAttached: \(security.utils.isDebuggerAttached())")
        appendLog("hasSuspiciousEnvironment (sim/DYLD heuristics): \(security.utils.hasSuspiciousEnvironment())")
      } catch {
        appendLog("wipe/env error: \(error.localizedDescription)")
      }
    }
  }

  private func runExecutableHash() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let snap = try await security.utils.snapshotExecutableHash(algorithm: .sha256)
        let ok = try await security.utils.verifyExecutableHashSnapshot(snap, algorithm: .sha256)
        appendLog("Executable hash snapshot verify: \(ok) (prefix \(snap.prefix(12)))")
      } catch {
        appendLog("executable hash error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Helpers

  private func clearLog() {
    logView.text = ""
    appendLog("Log cleared.")
  }

  private func makeDemoFile(name: String, content: String) throws -> URL {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dir = docs.appendingPathComponent("FKSecurityDemo", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent(name)
    try Data(content.utf8).write(to: url, options: [.atomic])
    return url
  }

  private func appendLog(_ message: String) {
    let ts = DateFormatter.fkSecurityLogFormatter.string(from: Date())
    logView.text.append("[\(ts)] \(message)\n")
    let end = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(end)
  }
}

private extension DateFormatter {
  static let fkSecurityLogFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "HH:mm:ss.SSS"
    return f
  }()
}
