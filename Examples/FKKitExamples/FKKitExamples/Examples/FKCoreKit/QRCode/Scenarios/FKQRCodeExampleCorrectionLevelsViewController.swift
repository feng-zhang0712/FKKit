import FKCoreKit
import UIKit

final class FKQRCodeExampleCorrectionLevelsViewController: FKQRCodeExampleBaseViewController {
  private let gridStack = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Correction Levels"

    gridStack.axis = .vertical
    gridStack.spacing = 12
    gridStack.alignment = .leading

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Render L / M / Q / H grid") { [weak self] in
      self?.renderGrid()
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeCorrectionLevel",
        description: "Higher correction tolerates damage and center logos. All codes encode the same URL; compare module density.",
        body: body
      )
    )
    contentStack.addArrangedSubview(gridStack)
    addClearLogButton()
    renderGrid()
  }

  private func renderGrid() {
    gridStack.arrangedSubviews.forEach { view in
      gridStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    let content = "https://example.com/correction-demo"
    for level in FKQRCodeCorrectionLevel.allCases {
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 160, height: 160)
      options.correctionLevel = level

      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 12
      row.alignment = .center
      row.distribution = .fill

      let label = UILabel()
      label.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
      label.text = level.rawValue
      label.setContentHuggingPriority(.required, for: .horizontal)
      label.setContentCompressionResistancePriority(.required, for: .horizontal)
      label.widthAnchor.constraint(equalToConstant: 24).isActive = true

      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.backgroundColor = .secondarySystemGroupedBackground
      imageView.layer.cornerRadius = 8
      imageView.clipsToBounds = true
      imageView.setContentHuggingPriority(.required, for: .horizontal)
      imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

      do {
        imageView.image = try FKQRCodeGenerator.makeImage(from: content, options: options)
        log("correction.\(level.rawValue): ok")
      } catch let error as FKQRCodeError {
        log("correction.\(level.rawValue): \(FKQRCodeExampleFormatting.describe(error))")
      } catch {
        log("correction.\(level.rawValue): \(error.localizedDescription)")
      }

      row.addArrangedSubview(label)
      row.addArrangedSubview(imageView)
      NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 120),
        imageView.heightAnchor.constraint(equalToConstant: 120),
      ])
      gridStack.addArrangedSubview(row)
    }
    showPreview(nil)
  }
}
