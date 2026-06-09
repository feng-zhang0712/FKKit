import UIKit

enum FKImageViewI18n {
  static var offlineMessage: String {
    FKUIKitI18n.string("fkuikit.image.error.offline")
  }

  static var networkMessage: String {
    FKUIKitI18n.string("fkuikit.image.error.network")
  }

  static var decodeMessage: String {
    FKUIKitI18n.string("fkuikit.image.error.decode")
  }

  static var retryTitle: String {
    FKUIKitI18n.string("fkuikit.image.action.retry")
  }
}
