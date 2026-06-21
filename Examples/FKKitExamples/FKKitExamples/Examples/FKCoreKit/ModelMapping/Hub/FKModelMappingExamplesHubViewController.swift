import UIKit

/// Grouped index of ``FKModelMapping`` examples under `FKCoreKit/Components/ModelMapping`.
final class FKModelMappingExamplesHubViewController: UITableViewController {
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
      title: "Codable fundamentals",
      rows: [
        Row(
          title: "Standard Codable",
          subtitle: "FKModelMapper / FKJSONCodec decode & encode, FKMappingFixture bundled JSON",
          make: { FKModelMappingExampleCodableBasicsViewController() }
        ),
        Row(
          title: "Snake case API",
          subtitle: ".apiDefault key strategy, FKNetworkClient decoder injection, strict comparison",
          make: { FKModelMappingExampleSnakeCaseViewController() }
        ),
      ]
    ),
    Section(
      title: "Lenient typing & wrappers",
      rows: [
        Row(
          title: "Lenient scalars",
          subtitle: "String numbers, empty strings → nil, FKMap, decodeLenient warnings",
          make: { FKModelMappingExampleLenientScalarsViewController() }
        ),
        Row(
          title: "Date formats",
          subtitle: "ISO-8601, epoch seconds, formatted strategy, FKDateTransform",
          make: { FKModelMappingExampleDateFormatsViewController() }
        ),
        Row(
          title: "Property wrappers",
          subtitle: "@FKDefault, @FKLossyArray, FKIntTransform, FKTransformRegistry",
          make: { FKModelMappingExamplePropertyWrappersViewController() }
        ),
        Row(
          title: "Strict vs lenient",
          subtitle: "Configuration presets, failure modes, FKMappingError coding paths",
          make: { FKModelMappingExampleStrictVsLenientViewController() }
        ),
      ]
    ),
    Section(
      title: "Dictionary mapping",
      rows: [
        Row(
          title: "Dictionary mapper",
          subtitle: "FKDictionaryMapper, FKJSONObject, decodeDecodable fallback",
          make: { FKModelMappingExampleDictionaryMappingViewController() }
        ),
        Row(
          title: "Nested paths",
          subtitle: "profile.display_name, tags[n], FKMap.nestedObject",
          make: { FKModelMappingExampleNestedPathsViewController() }
        ),
        Row(
          title: "Manual FKMappable",
          subtitle: "Conditional field merge, defaults, lenient dictionary warnings",
          make: { FKModelMappingExampleManualMappableViewController() }
        ),
        Row(
          title: "Polymorphic feed",
          subtitle: "FKPolymorphicDecodable discriminator arrays and FKPolymorphicRegistry",
          make: { FKModelMappingExamplePolymorphicViewController() }
        ),
      ]
    ),
    Section(
      title: "API envelopes",
      rows: [
        Row(
          title: "Response envelope",
          subtitle: "decodeEnvelope, FKResponseEnvelopeProcessor, success-flag preset, business failure → NetworkError",
          make: { FKModelMappingExampleResponseEnvelopeViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration & output",
      rows: [
        Row(
          title: "Encoding",
          subtitle: "convertToSnakeCase encode, dictionary(from:), FKJSONCodec data output",
          make: { FKModelMappingExampleEncodingViewController() }
        ),
        Row(
          title: "Network integration",
          subtitle: "FKNetworkClient mock + FKResponseEnvelopeInterceptor + shared JSONDecoder",
          make: { FKModelMappingExampleNetworkIntegrationViewController() }
        ),
        Row(
          title: "Pagination & utilities",
          subtitle: "FKPage, FKListResponse, FKModelMapper.shared, FKMappingLogging",
          make: { FKModelMappingExamplePaginationTemplatesViewController() }
        ),
        Row(
          title: "Complex payload mapping",
          subtitle: "Nested envelope hub, polymorphic blocks, embedded JSON, mixed scalars and dates",
          make: { FKModelMappingExampleComplexPayloadViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKModelMapping"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
