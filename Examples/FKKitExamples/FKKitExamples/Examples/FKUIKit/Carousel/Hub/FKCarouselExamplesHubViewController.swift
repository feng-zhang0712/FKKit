import UIKit

/// Entry hub for ``FKCarousel`` and ``FKImageBanner`` demos.
final class FKCarouselExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "FKImageBanner · Marketing",
      rows: [
        Row(
          title: "Home hero",
          subtitle: "homeHero preset · infinite loop · auto-scroll · tap & link delegate",
          make: { FKImageBannerHomeHeroExampleViewController() }
        ),
        Row(
          title: "Card peek promo",
          subtitle: "compactPromo preset · peek layout · FKCornerShadow card chrome",
          make: { FKImageBannerCardPeekExampleViewController() }
        ),
        Row(
          title: "Mixed overlay",
          subtitle: "Title, subtitle, CTA, accessibility-only overlay visibility",
          make: { FKImageBannerMixedOverlayExampleViewController() }
        ),
        Row(
          title: "Failure fallback",
          subtitle: "Broken URL · showErrorPlaceholder · named asset slide",
          make: { FKImageBannerFailureFallbackExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKImageBanner · States",
      rows: [
        Row(
          title: "Single slide & empty",
          subtitle: "Indicator hidden · auto-scroll off · empty collapse policy",
          make: { FKImageBannerStatesExampleViewController() }
        ),
        Row(
          title: "Dynamic Type overlay",
          subtitle: "Large content size · fixedBannerHeight vs growBanner policies",
          make: { FKImageBannerDynamicTypeExampleViewController() }
        ),
        Row(
          title: "Presets gallery",
          subtitle: "homeHero · compactPromo · edgeToEdge · onboarding configurations",
          make: { FKImageBannerPresetsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKCarousel · Layout & indicators",
      rows: [
        Row(
          title: "Onboarding cards",
          subtitle: "pageProvider · fraction indicator · bounded paging (no loop)",
          make: { FKCarouselOnboardingExampleViewController() }
        ),
        Row(
          title: "Data source pages",
          subtitle: "FKCarouselDataSource · view reuse · non-interactive page",
          make: { FKCarouselDataSourceExampleViewController() }
        ),
        Row(
          title: "Indicator styles",
          subtitle: "Dots · bar · fraction · line · custom renderer · placement",
          make: { FKCarouselIndicatorStylesExampleViewController() }
        ),
        Row(
          title: "Layout modes",
          subtitle: "fixedPageWidth · insetCard · indicator below · interPageSpacing",
          make: { FKCarouselLayoutModesExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKCarousel · Behavior & integration",
      rows: [
        Row(
          title: "Auto-scroll & infinite loop",
          subtitle: "Interval · direction · pause rules · Reduce Motion note",
          make: { FKCarouselAutoScrollExampleViewController() }
        ),
        Row(
          title: "Manual control",
          subtitle: "scrollToPage · scrollProgress · stateSnapshot readout",
          make: { FKCarouselManualControlExampleViewController() }
        ),
        Row(
          title: "Table header embed",
          subtitle: "UITableView tableHeaderView · timer lifecycle while scrolling",
          make: { FKCarouselTableHeaderExampleViewController() }
        ),
        Row(
          title: "Delegate & callbacks log",
          subtitle: "FKCarouselDelegate · FKImageBannerDelegate · FKCarouselCallbacks",
          make: { FKCarouselDelegateLogExampleViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKImageBannerRepresentable · FKCarouselRepresentable · currentPage binding",
          make: { FKCarouselSwiftUIExampleViewController() }
        ),
        Row(
          title: "RTL layout",
          subtitle: "Force RTL semantic content · mirrored paging direction",
          make: { FKCarouselRTLExampleViewController() }
        ),
      ]
    ),
  ]

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Carousel"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 76
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.numberOfLines = 0
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
