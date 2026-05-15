import Foundation
import FKCompositeKit

/// Local-only catalog for Filter dropdown demos (English copy).
enum FKFilterExampleStaticData {
  /// Two-column list: browse by top-level category.
  static let catalogTwoColumn: FKFilterTwoColumnModel = {
    let all = FKFilterTwoColumnModel.Category(id: .init(rawValue: "cat.all"), title: "All", isSelected: true)
    let regulations = FKFilterTwoColumnModel.Category(id: .init(rawValue: "cat.reg"), title: "Regulations", isSelected: false)
    let cases = FKFilterTwoColumnModel.Category(id: .init(rawValue: "cat.case"), title: "Cases", isSelected: false)
    let allSections: [FKFilterSection] = []
    let regulationSections: [FKFilterSection] = [
      .init(
        id: .init(rawValue: "reg.sec1"),
        title: "Topics",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "reg.all"), title: "All", isSelected: true),
          .init(id: .init(rawValue: "reg.disclosure"), title: "Disclosure", isSelected: false),
          .init(id: .init(rawValue: "reg.trading"), title: "Market conduct", isSelected: false),
        ]
      ),
    ]
    let caseSections: [FKFilterSection] = [
      .init(
        id: .init(rawValue: "case.sec1"),
        title: "Practice areas",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "case.all"), title: "All", isSelected: true),
          .init(id: .init(rawValue: "case.ethics"), title: "Ethics", isSelected: false),
          .init(id: .init(rawValue: "case.enforcement"), title: "Enforcement", isSelected: false),
        ]
      ),
    ]
    return FKFilterTwoColumnModel(
      categories: [all, regulations, cases],
      sectionsByCategoryID: [all.id: allSections, regulations.id: regulationSections, cases.id: caseSections]
    )
  }()

  /// Two-column grid: training categories with titled sections (supports header collapse demos).
  static let trainingTwoColumn: FKFilterTwoColumnModel = {
    let leadership = FKFilterTwoColumnModel.Category(id: .init(rawValue: "tr.lead"), title: "Leadership", isSelected: true)
    let compliance = FKFilterTwoColumnModel.Category(id: .init(rawValue: "tr.comp"), title: "Compliance", isSelected: false)
    let skills = FKFilterTwoColumnModel.Category(id: .init(rawValue: "tr.skill"), title: "Professional skills", isSelected: false)
    let webSchool = FKFilterTwoColumnModel.Category(id: .init(rawValue: "tr.web"), title: "Web school", isSelected: false)
    let simpleAll: [FKFilterSection] = [
      .init(id: .init(rawValue: "tr.all"), selectionMode: .single, items: [.init(id: .init(rawValue: "tr.all.item"), title: "All", isSelected: true)]),
    ]
    let webSections: [FKFilterSection] = [
      .init(
        id: .init(rawValue: "tr.sec1"),
        title: "Policy updates",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "tr.p1"), title: "Annual priorities", isSelected: true),
          .init(id: .init(rawValue: "tr.p2"), title: "Supervisory letters", isSelected: false),
          .init(id: .init(rawValue: "tr.p3"), title: "Risk alerts", isSelected: false),
        ]
      ),
      .init(
        id: .init(rawValue: "tr.sec2"),
        title: "Product lines",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "tr.l1"), title: "Equities", isSelected: false),
          .init(id: .init(rawValue: "tr.l2"), title: "Fixed income", isSelected: false),
          .init(id: .init(rawValue: "tr.l3"), title: "Derivatives", isSelected: false),
        ]
      ),
      .init(
        id: .init(rawValue: "tr.sec3"),
        title: "Reference (empty)",
        selectionMode: .single,
        items: []
      ),
      .init(
        id: .init(rawValue: "tr.sec4"),
        title: "Electives",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "tr.e1"), title: "Well-being", isSelected: false),
          .init(id: .init(rawValue: "tr.e2"), title: "ESG overview", isSelected: false),
        ]
      ),
    ]
    return FKFilterTwoColumnModel(
      categories: [leadership, compliance, skills, webSchool],
      sectionsByCategoryID: [leadership.id: simpleAll, compliance.id: simpleAll, skills.id: simpleAll, webSchool.id: webSections]
    )
  }()

  static let fileTypeSections: [FKFilterSection] = [
    .init(
      id: .init(rawValue: "file-types"),
      selectionMode: .single,
      items: [
        .init(id: .init(rawValue: "file-all"), title: "All", isSelected: true),
        .init(id: .init(rawValue: "file-word"), title: "Word", isSelected: false),
        .init(id: .init(rawValue: "file-excel"), title: "Excel", isSelected: false),
        .init(id: .init(rawValue: "file-ppt"), title: "PowerPoint", isSelected: false),
        .init(id: .init(rawValue: "file-pdf"), title: "PDF", isSelected: false),
        .init(id: .init(rawValue: "file-media"), title: "Audio / video", isSelected: false),
        .init(id: .init(rawValue: "file-image"), title: "Images", isSelected: false),
        .init(id: .init(rawValue: "file-other"), title: "Other", isSelected: false),
      ]
    ),
  ]

  static let platformSections: [FKFilterSection] = [
    .init(
      id: .init(rawValue: "platform"),
      selectionMode: .single,
      items: [
        .init(id: .init(rawValue: "platform-all"), title: "All", isSelected: true),
        .init(id: .init(rawValue: "platform-global"), title: "Global catalog", isSelected: false),
        .init(id: .init(rawValue: "platform-local"), title: "This organization", isSelected: false),
        .init(id: .init(rawValue: "platform-partner"), title: "Partner sites", isSelected: false),
      ]
    ),
  ]

  static let tagsSections: [FKFilterSection] = [
    .init(
      id: .init(rawValue: "tags"),
      selectionMode: .multiple,
      items: [
        .init(id: .init(rawValue: "tag-all"), title: "All", isSelected: false),
        .init(id: .init(rawValue: "tag-ib"), title: "Investment banking", isSelected: false),
        .init(id: .init(rawValue: "tag-research"), title: "Equity research", isSelected: false),
        .init(id: .init(rawValue: "tag-risk"), title: "Risk", isSelected: false),
        .init(id: .init(rawValue: "tag-compliance"), title: "Compliance", isSelected: false),
        .init(id: .init(rawValue: "tag-wealth"), title: "Wealth management", isSelected: false),
        .init(id: .init(rawValue: "tag-tech"), title: "Technology", isSelected: false),
        .init(id: .init(rawValue: "tag-ops"), title: "Operations", isSelected: false),
        .init(id: .init(rawValue: "tag-esg"), title: "ESG", isSelected: false),
        .init(id: .init(rawValue: "tag-other"), title: "Other", isSelected: false),
      ]
    ),
  ]

  static let sortSection: FKFilterSection = .init(
    id: .init(rawValue: "sort"),
    selectionMode: .single,
    items: [
      .init(id: .init(rawValue: "sort-latest"), title: "Newest", isSelected: true),
      .init(id: .init(rawValue: "sort-popular"), title: "Popular", isSelected: false),
      .init(id: .init(rawValue: "sort-rated"), title: "Top rated", isSelected: false),
    ]
  )
}
