import FKUIKit
import UIKit

/// Presents ``FKRatingControl`` inside centered ``FKSheetPresentationController`` modals.
final class FKRatingExampleSheetIntegrationViewController: FKRatingExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Center sheet + rating"

    contentStack.addArrangedSubview(makeIntroCard())
    contentStack.addArrangedSubview(makeScenarioCard(
      title: "Quick rate (center card)",
      caption: "Uses `FKSheetPresentationConfiguration.centerCard` with fitted sizing. Submit stays disabled until a star is selected.",
      buttonTitle: "Present quick rate",
      configuration: FKRatingSheetExampleSupport.centerCardConfiguration(),
      contentFactory: { FKRatingQuickRateSheetContentViewController() }
    ))
    contentStack.addArrangedSubview(makeScenarioCard(
      title: "Feedback form (center fitted)",
      caption: "Half-star ``FKRatingControl`` plus a comment field. Demonstrates taller fitted center content.",
      buttonTitle: "Present feedback sheet",
      configuration: FKRatingSheetExampleSupport.centerCardConfiguration(width: 360),
      contentFactory: { FKRatingFeedbackSheetContentViewController() }
    ))
    contentStack.addArrangedSubview(makeScenarioCard(
      title: "App Store–style prompt",
      caption: "App Store–style centered alert with fitted sizing. Dismiss only via Not Now or Submit — no swipe or tap-outside.",
      buttonTitle: "Present App Store prompt",
      configuration: FKRatingSheetExampleSupport.appStoreConfiguration(),
      contentFactory: { FKRatingAppStoreSheetContentViewController() }
    ))
  }

  private func makeIntroCard() -> UIStackView {
    let box = FKRatingExampleSupport.sectionContainer(title: "FKSheetPresentationController × FKRatingControl")
    box.addArrangedSubview(
      FKRatingExampleSupport.caption(
        "These demos use the `.center` layout mode (floating card / alert). Quick rate and feedback close when you tap outside; App Store prompt uses Not Now / Submit only."
      )
    )
    return box
  }

  private func makeScenarioCard(
    title: String,
    caption: String,
    buttonTitle: String,
    configuration: FKSheetPresentationConfiguration,
    contentFactory: @escaping () -> UIViewController
  ) -> UIStackView {
    let box = FKRatingExampleSupport.sectionContainer(title: title)
    box.addArrangedSubview(FKRatingExampleSupport.caption(caption))

    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.cornerStyle = .large
    button.setTitle(buttonTitle, for: .normal)
    button.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let content = contentFactory()
      _ = FKRatingSheetExampleSupport.present(
        content: content,
        from: self,
        configuration: configuration
      )
    }, for: .touchUpInside)
    box.addArrangedSubview(button)
    return box
  }
}
