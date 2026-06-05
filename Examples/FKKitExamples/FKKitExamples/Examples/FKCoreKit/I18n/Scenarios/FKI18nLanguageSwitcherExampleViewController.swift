import FKCoreKit
import UIKit

/// Demonstrates in-app switching across all ``FKI18nRecommendedLanguages``.
final class FKI18nLanguageSwitcherExampleViewController: UITableViewController {

  private struct LanguageRow {
    let code: String
    var displayName: String { FKI18nLanguage(code: code).displayName() }
    var isRTL: Bool { FKI18nRecommendedLanguages.isRightToLeft(code: code) }
  }

  private let languages = FKI18nRecommendedLanguages.languageCodes.map { LanguageRow(code: $0) }

  private let headerContainer = UIView()
  private let previewLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .title2)
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }()

  private let detailLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }()

  private var observationToken: FKI18nObservationToken?

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Language Switcher"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    installTableHeader()
    observationToken = FKI18nExampleSupport.observeLanguageChange(on: self) { [weak self] in
      self?.refreshPreview()
      self?.tableView.reloadData()
    }
    refreshPreview()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    resizeTableHeaderIfNeeded()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    languages.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let language = languages[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()

    let isSelected = FKI18nManager.shared.currentLanguageCode == language.code
    config.text = isSelected ? "✓ \(language.displayName)" : language.displayName
    config.secondaryText = language.isRTL ? "\(language.code) · RTL" : language.code
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = isSelected ? .checkmark : .none
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    FKI18nManager.shared.setLanguageCode(languages[indexPath.row].code)
  }

  private func installTableHeader() {
    let headerStack = UIStackView(arrangedSubviews: [previewLabel, detailLabel])
    headerStack.axis = .vertical
    headerStack.spacing = 8
    headerStack.translatesAutoresizingMaskIntoConstraints = false

    headerContainer.addSubview(headerStack)
    NSLayoutConstraint.activate([
      headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
      headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
      headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
      headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
    ])

    tableView.tableHeaderView = headerContainer
    resizeTableHeaderIfNeeded()
  }

  private func resizeTableHeaderIfNeeded() {
    guard let header = tableView.tableHeaderView else { return }
    let width = tableView.bounds.width
    guard width > 0 else { return }

    header.frame.size.width = width
    let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
    let height = header.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height

    guard header.frame.height != height else { return }
    header.frame.size.height = height
    tableView.tableHeaderView = header
  }

  private func refreshPreview() {
    let i18n = FKI18nManager.shared
    previewLabel.text = FKI18nExampleSupport.localized("i18n.demo.greeting")
    detailLabel.text = FKI18nExampleSupport.localized(
      "i18n.demo.language.current",
      variables: ["language": i18n.currentLanguage.displayName()]
    )
    let semantic: UISemanticContentAttribute = i18n.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
    view.semanticContentAttribute = semantic
    tableView.semanticContentAttribute = semantic
    previewLabel.textAlignment = i18n.isRightToLeft ? .right : .center
    detailLabel.textAlignment = i18n.isRightToLeft ? .right : .center
    resizeTableHeaderIfNeeded()
  }
}
