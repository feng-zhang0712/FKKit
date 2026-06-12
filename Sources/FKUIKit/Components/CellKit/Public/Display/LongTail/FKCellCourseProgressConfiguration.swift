import Foundation
public struct FKCellCourseProgressConfiguration: Sendable, Equatable {
  public var courseTitle: String; public var progress: Double; public var percentText: String?
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(courseTitle: String, progress: Double, percentText: String? = nil, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.courseTitle=courseTitle; self.progress=progress; self.percentText=percentText
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
