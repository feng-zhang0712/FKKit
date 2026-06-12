import Foundation
public struct FKCellInlineEmptyConfiguration: Sendable, Equatable {
  public var title: String; public var message: String?; public var iconSymbolName: String
  public var actionTitle: String?; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, message: String? = nil, iconSymbolName: String = "tray",
    actionTitle: String? = nil, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .none, isLastInSection: Bool = true) {
    self.title = title; self.message = message; self.iconSymbolName = iconSymbolName
    self.actionTitle = actionTitle; self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy; self.isLastInSection = isLastInSection
  }
}
