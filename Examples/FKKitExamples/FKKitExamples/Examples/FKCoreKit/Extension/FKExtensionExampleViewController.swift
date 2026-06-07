import UIKit
import FKCoreKit

/// Interactive demo for FKCoreKit `Extension` APIs (`fk_*` helpers and toolbox types).
final class FKExtensionExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()
  private let demoImageView = UIImageView()
  private let sampleCardView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Extension"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("Extension demo initialized.")
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    demoImageView.translatesAutoresizingMaskIntoConstraints = false
    demoImageView.contentMode = .scaleAspectFit
    demoImageView.backgroundColor = .tertiarySystemBackground
    demoImageView.layer.cornerRadius = 8
    demoImageView.clipsToBounds = true

    sampleCardView.translatesAutoresizingMaskIntoConstraints = false
    sampleCardView.backgroundColor = .systemTeal
    sampleCardView.layer.cornerRadius = 10

    let actions: [(String, Selector)] = [
      ("1) Date: Format + Timestamp + Relative", #selector(demoDateUtilities)),
      ("2) String: Validation + Mask + Encoding", #selector(demoStringUtilities)),
      ("3) Number: Grouping + Decimal Ops", #selector(demoNumberUtilities)),
      ("4) Device + Bundle metadata", #selector(demoDeviceUtilities)),
      ("5) UI: Hex + Adaptation + Snapshot", #selector(demoUIUtilities)),
      ("6) Collection: Safe Access + JSON", #selector(demoCollectionUtilities)),
      ("7) Image: Compress + Convert + Rounded", #selector(demoImageUtilities)),
      ("8) FileManager + App actions", #selector(demoCommonUtilities)),
      ("Clear Output", #selector(clearOutput)),
    ]

    for (title, selector) in actions {
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: selector, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(sampleCardView)
    view.addSubview(demoImageView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.36),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      sampleCardView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      sampleCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      sampleCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      sampleCardView.heightAnchor.constraint(equalToConstant: 44),

      demoImageView.topAnchor.constraint(equalTo: sampleCardView.bottomAnchor, constant: 8),
      demoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      demoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      demoImageView.heightAnchor.constraint(equalToConstant: 90),

      outputView.topAnchor.constraint(equalTo: demoImageView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  @objc private func demoDateUtilities() {
    let now = Date()
    let standard = now.fk_formatted("yyyy-MM-dd HH:mm:ss")
    let timestamp = now.fk_unixTimestamp
    let restored = Date(fk_unixTimestamp: timestamp)
    let restoredText = restored.fk_formatted("yyyy-MM-dd HH:mm:ss")
    let twoHoursAgo = now.fk_byAdding(DateComponents(hour: -2)) ?? now
    let relative = twoHoursAgo.fk_relativeDescription(reference: now)
    let isValid = "2026-04-20".fk_isValidDate(format: "yyyy-MM-dd")

    appendOutput("Date string: \(standard)")
    appendOutput("Timestamp: \(timestamp)")
    appendOutput("Restored date: \(restoredText)")
    appendOutput("Relative time: \(relative)")
    appendOutput("Date validation: \(isValid)")
  }

  @objc private func demoStringUtilities() {
    appendOutput("Phone valid: \("13800138000".fk_isValidPhone)")
    appendOutput("Email valid: \("dev@example.com".fk_isValidEmail)")
    appendOutput("ID valid: \("110101199001011234".fk_isValidIDCard)")
    appendOutput("Strong password: \("Aa@12345".fk_isStrongPassword)")

    let extracted = "IDs: A-10 B-20".fk_extractMatches(pattern: #"[A-Z]-\d+"#)
    appendOutput("Extracted groups: \(extracted)")

    let trimmed = "  hello Extension \n".fk_trimmed
    appendOutput("Trimmed: \(trimmed)")
    appendOutput("Masked phone: \("13800138000".fk_maskedPhone())")
    appendOutput("Masked email: \("john.doe@example.com".fk_maskedEmail())")
    appendOutput("Base64 decoded: \("Extension".fk_base64EncodedString.fk_base64DecodedString ?? "failed")")
    appendOutput("HTML unescaped: \("<title>FK</title>".fk_htmlEscaped.fk_htmlUnescaped)")
  }

  @objc private func demoNumberUtilities() {
    let amount = Decimal(string: "1234567.8912") ?? 0
    appendOutput("Grouped amount: \(amount.fk_formattedAmount())")
    appendOutput("Rounded: \(amount.fk_rounded(scale: 2))")
    appendOutput("Truncated: \(amount.fk_truncated(scale: 2))")
    appendOutput("Percent: \(0.1265.fk_formattedPercent())")
  }

  @objc private func demoDeviceUtilities() {
    let model = FKDeviceInfo.modelIdentifier()
    let appVersion = Bundle.main.fk_shortVersionString
    let build = Bundle.main.fk_buildVersionString
    let disk = FKDeviceInfo.diskSpace()

    appendOutput("Device model: \(model)")
    appendOutput("App version/build: \(appVersion) (\(build))")
    appendOutput("Disk free/total: \(disk.free) / \(disk.total)")

    FKDeviceInfo.networkStatus { [weak self] status in
      self?.appendOutput("Network status: \(status)")
    }
  }

  @MainActor
  @objc private func demoUIUtilities() {
    let color = UIColor(fk_hexString: "#3366FF") ?? .systemBlue
    let hex = color.fk_hexString ?? "n/a"
    let adaptiveFont = UIFont.fk_adaptiveSystemFont(size: 16, weight: .medium)

    sampleCardView.backgroundColor = color
    sampleCardView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
    _ = sampleCardView.fk_addGradient(colors: [color.withAlphaComponent(0.7), .systemPurple])
    sampleCardView.fk_applyShadow()

    outputView.font = adaptiveFont
    demoImageView.image = sampleCardView.fk_snapshotImage(afterScreenUpdates: true)
    appendOutput("Color hex round-trip: \(hex)")
    appendOutput("Adaptive font size: \(adaptiveFont.pointSize)")
    appendOutput("Main-thread snapshot updated.")
  }

  @objc private func demoCollectionUtilities() {
    struct DemoUser: Decodable {
      let id: Int
      let name: String
    }

    let values = [1, 2, 2, 3, 3, 4]
    let unique = values.fk_uniqued
    let safeValue = values[fk_safe: 99]

    let payload: [String: Any] = ["id": 7, "name": "FK"]
    let json = payload.fk_jsonString() ?? "{}"
    let user = payload.fk_decodeJSON(DemoUser.self)

    appendOutput("Unique values: \(unique)")
    appendOutput("Safe array access at 99: \(String(describing: safeValue))")
    appendOutput("JSON payload: \(json)")
    appendOutput("Decoded user: \(String(describing: user?.name))")
  }

  @objc private func demoImageUtilities() {
    let raw = UIImage.fk_solidColor(.systemOrange, size: CGSize(width: 120, height: 120))
    let rounded = raw.fk_roundingCorners(20)
    demoImageView.image = rounded

    let compressedBytes = rounded.fk_jpegData(maxBytes: 12 * 1024)?.count ?? 0
    let base64 = rounded.fk_jpegBase64String(compressionQuality: 0.8) ?? ""
    let restored = base64.isEmpty ? nil : UIImage.fk_image(fromBase64JPEG: base64)

    appendOutput("Compressed bytes: \(compressedBytes)")
    appendOutput("Base64 length: \(base64.count)")
    appendOutput("Restored image success: \(restored != nil)")
  }

  @objc private func demoCommonUtilities() {
    let docs = FileManager.fk_documentsDirectory.path
    let nilCheck = FKValueParsing.isNilOrEmpty("   ")
    let intValue = FKValueParsing.int(from: "42") ?? -1
    let safeResult = FKValueParsing.catching { try riskyDivision(10, by: 0) }

    appendOutput("Documents path: \(docs)")
    appendOutput("Nil or empty check: \(nilCheck)")
    appendOutput("String->Int conversion: \(intValue)")
    appendOutput("Safe execution result: \(safeResult)")

    UIApplication.fk_vibrate()

    let alert = UIAlertController(
      title: "Open System Settings?",
      message: "This demonstrates UIApplication.fk_openAppSettings().",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { _ in
      UIApplication.fk_openAppSettings()
    }))
    present(alert, animated: true)
  }

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("Output cleared.")
  }

  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(Self.demoTimeFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }

  private func riskyDivision(_ lhs: Int, by rhs: Int) throws -> Int {
    enum DivisionError: Error { case divideByZero }
    guard rhs != 0 else { throw DivisionError.divideByZero }
    return lhs / rhs
  }

  private static let demoTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
