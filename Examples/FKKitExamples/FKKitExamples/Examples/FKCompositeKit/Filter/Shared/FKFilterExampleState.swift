import Foundation
import FKCompositeKit

/// Mutable filter models for examples; paired with ``FKFilterExamplePanelFactoryBuilder``.
@MainActor
final class FKFilterExampleState {
  var knowledgeModel: FKFilterTwoColumnModel?
  var courseModel: FKFilterTwoColumnModel?
  var fileTypeSections: [FKFilterSection] = []
  var platformSections: [FKFilterSection] = []
  var tagsSections: [FKFilterSection] = []
  var sortSection: FKFilterSection?

  init() {}

  /// All six panels populated (scrollable strip example).
  static func presetFullHub() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.knowledgeModel = FKFilterExampleStaticData.catalogTwoColumn
    s.courseModel = FKFilterExampleStaticData.trainingTwoColumn
    s.fileTypeSections = FKFilterExampleStaticData.fileTypeSections
    s.platformSections = FKFilterExampleStaticData.platformSections
    s.tagsSections = FKFilterExampleStaticData.tagsSections
    s.sortSection = FKFilterExampleStaticData.sortSection
    return s
  }

  /// Equal-width strip: scope · training grid · tags.
  static func presetEqualBusiness() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.courseModel = FKFilterExampleStaticData.trainingTwoColumn
    s.platformSections = FKFilterExampleStaticData.platformSections
    s.tagsSections = FKFilterExampleStaticData.tagsSections
    return s
  }

  /// Equal-width strip: browse list · formats · sort.
  static func presetEqualKnowledge() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.knowledgeModel = FKFilterExampleStaticData.catalogTwoColumn
    s.fileTypeSections = FKFilterExampleStaticData.fileTypeSections
    s.sortSection = FKFilterExampleStaticData.sortSection
    return s
  }

  /// Three compact tabs for animation / backdrop experiments.
  static func presetCompactThree() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.knowledgeModel = FKFilterExampleStaticData.catalogTwoColumn
    s.fileTypeSections = FKFilterExampleStaticData.fileTypeSections
    s.sortSection = FKFilterExampleStaticData.sortSection
    return s
  }
}
