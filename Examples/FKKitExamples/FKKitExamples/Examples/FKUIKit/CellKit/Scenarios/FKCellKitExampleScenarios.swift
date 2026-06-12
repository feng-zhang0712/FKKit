import FKCoreKit
import FKUIKit
import UIKit

/// Design-doc composed flows (#1–#27) built from explicit CellKit rows.
@MainActor
enum FKCellKitExampleScenarios {
  // MARK: - Settings (#1–#9)

  static func settingsGeneral() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Settings — General",
      sections: [
        FKCellKitExampleSection(
          title: "Apple ID",
          footer: "Manage your account, iCloud, media, and purchases.",
          rows: [
            row(FKCellHeroCell.self, title: "Hero") {
              $0.configure(with: FKCellHeroRow(
                id: "hero",
                configuration: FKCellHeroConfiguration(
                  icon: FKCellIconContent(symbolName: "person.crop.circle.fill"),
                  title: "Frank Chen",
                  description: "Apple ID, iCloud+, Media & Purchases"
                )
              ))
            },
            row(FKCellIconValueDisclosureCell.self, title: "Name") {
              $0.configure(with: FKCellIconValueDisclosureRow(
                id: "name",
                icon: FKCellIconContent(symbolName: "person.fill"),
                title: "Name",
                value: "Frank Chen",
                showsDisclosure: true
              ))
            },
            row(FKCellValueDisclosureCell.self, title: "Phone") {
              $0.configure(with: FKCellValueDisclosureRow(
                id: "phone",
                title: "Phone Numbers",
                value: "+1 (555) 010-2030"
              ))
            },
          ]
        ),
        FKCellKitExampleSection(
          title: "Preferences",
          rows: [
            row(FKCellDisclosureCell.self, title: "Notifications") {
              $0.configure(with: FKCellDisclosureRow(id: "notifications", title: "Notifications"))
            },
            row(FKCellDisclosureCell.self, title: "Sounds") {
              $0.configure(with: FKCellDisclosureRow(id: "sounds", title: "Sounds & Haptics"))
            },
          ]
        ),
      ]
    )
  }

  static func settingsAbout() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Settings — About",
      sections: [
        FKCellKitExampleSection(
          title: "Device",
          rows: [
            row(FKCellKeyValueCell.self, title: "Model") {
              $0.configure(with: FKCellKeyValueRow(id: "model", title: "Model Name", value: "iPhone"))
            },
            row(FKCellKeyValueCell.self, title: "Version") {
              $0.configure(with: FKCellKeyValueRow(id: "version", title: "Software Version", value: "18.0"))
            },
            row(FKCellValueDisclosureCell.self, title: "Storage") {
              $0.configure(with: FKCellValueDisclosureRow(id: "storage", title: "Capacity", value: "256 GB"))
            },
            row(FKCellInfoCell.self, title: "Info") {
              $0.configure(with: FKCellInfoRow(
                id: "serial",
                icon: FKCellIconContent(symbolName: "number"),
                title: "Serial Number",
                subtitles: ["FK-DEMO-001"]
              ))
            },
          ]
        ),
      ]
    )
  }

  static func settingsSoftwareUpdate() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Software Update",
      sections: [
        FKCellKitExampleSection(
          title: nil,
          rows: [
            FKCellKitExampleSampleData.sampleCellAppUpdateCell(),
            row(FKCellRichTextCell.self, title: "Release Notes") {
              $0.configure(with: FKCellRichTextRow(
                id: "notes",
                configuration: FKCellRichTextConfiguration(
                  title: "What's New",
                  body: "• Improved performance\n• Bug fixes and security updates"
                )
              ))
            },
            row(FKCellStatusDetailCell.self, title: "Status") {
              $0.configure(with: FKCellStatusDetailRow(
                id: "status",
                configuration: FKCellStatusDetailConfiguration(
                  title: "Automatic Updates",
                  statusText: "On",
                  statusColor: .systemGreen,
                  body: "Your iPhone will download updates when connected to Wi-Fi."
                )
              ))
            },
            row(FKCellAlertActionCell.self, title: "Install") {
              $0.configure(with: FKCellAlertActionRow(
                id: "install",
                configuration: FKCellAlertActionConfiguration(
                  title: "Update Available",
                  body: "iOS 18.1 is ready to install.",
                  primaryAction: FKCellActionLink(title: "Download and Install")
                )
              ))
            },
          ]
        ),
      ]
    )
  }

  static func settingsAirDrop() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "AirDrop",
      sections: [
        FKCellKitExampleSection(
          headerConfiguration: FKCellSectionHeaderConfiguration(title: "Allow me to be discovered by"),
          footerConfiguration: FKCellSectionFooterConfiguration(
            text: "AirDrop lets you share instantly with people nearby."
          ),
          rows: [
            row(FKCellSelectionCell.self, title: "Receiving Off") {
              $0.configure(with: FKCellSelectionRow(id: "off", title: "Receiving Off", isSelected: false))
            },
            row(FKCellSelectionCell.self, title: "Contacts Only") {
              $0.configure(with: FKCellSelectionRow(id: "contacts", title: "Contacts Only", isSelected: true))
            },
            row(FKCellSelectionCell.self, title: "Everyone") {
              $0.configure(with: FKCellSelectionRow(id: "everyone", title: "Everyone for 10 Minutes", isSelected: false))
            },
          ]
        ),
        FKCellKitExampleSection(
          title: "Discoverability",
          rows: [
            row(FKCellSwitchCell.self, title: "Use Cellular Data") { cell in
              cell.configure(with: FKCellSwitchRow(id: "cellular", title: "Use Cellular Data", isOn: false))
              cell.onValueChanged = { isOn in FKToast.show("Cellular data: \(isOn ? "On" : "Off")") }
            },
          ]
        ),
      ]
    )
  }

  static func settingsLanguageRegion() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Language & Region",
      sections: [
        FKCellKitExampleSection(
          title: "Language",
          rows: [
            row(FKCellLanguageCell.self, title: "Language") {
              $0.configure(with: FKCellLanguageRow(
                id: "language",
                configuration: FKCellLanguageConfiguration(
                  languageName: "English (US)",
                  nativeName: "English",
                  flagIcon: FKCellIconContent(symbolName: "globe"),
                  isSelected: true
                )
              ))
            },
            row(FKCellPickerCell.self, title: "Region") {
              $0.configure(with: FKCellPickerRow(
                id: "region",
                configuration: FKCellPickerConfiguration(title: "Region", value: "United States")
              ))
            },
          ]
        ),
        FKCellKitExampleSection(
          title: "Order",
          footer: "Drag to reorder preferred languages.",
          rows: [
            FKCellKitExampleSampleData.sampleCellReorderCell(),
            FKCellKitExampleSampleData.sampleCellReorderCell(),
          ]
        ),
      ]
    )
  }

  static func settingsAutoFill() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "AutoFill",
      sections: [
        FKCellKitExampleSection(
          title: "Passwords",
          rows: [
            row(FKCellSwitchCell.self, title: "AutoFill Passwords") { cell in
              cell.configure(with: FKCellSwitchRow(id: "autofill", title: "AutoFill Passwords", isOn: true))
              cell.onValueChanged = { isOn in FKToast.show("AutoFill: \(isOn ? "On" : "Off")") }
            },
            row(FKCellCheckboxCell.self, title: "Passkeys") {
              $0.configure(with: FKCellCheckboxRow(
                id: "passkeys",
                configuration: FKCellCheckboxConfiguration(title: "Passkeys", isChecked: true)
              ))
            },
            row(FKCellPickerCell.self, title: "Default Provider") {
              $0.configure(with: FKCellPickerRow(
                id: "provider",
                configuration: FKCellPickerConfiguration(title: "Password Manager", value: "FKKit Passwords")
              ))
            },
          ]
        ),
      ]
    )
  }

  static func settingsStorage() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Storage",
      sections: [
        FKCellKitExampleSection(
          title: "Summary",
          rows: [
            FKCellKitExampleSampleData.sampleCellStorageSummaryCell(),
            row(FKCellValueDisclosureCell.self, title: "Recommendations") {
              $0.configure(with: FKCellValueDisclosureRow(id: "rec", title: "Recommendations", value: "3 items"))
            },
            row(FKCellInfoCell.self, title: "Breakdown") {
              $0.configure(with: FKCellInfoRow(
                id: "breakdown",
                icon: FKCellIconContent(symbolName: "internaldrive"),
                title: "System Data",
                subtitles: ["12.4 GB"]
              ))
            },
          ]
        ),
      ]
    )
  }

  static func settingsLegal() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Legal & Regulatory",
      sections: [
        FKCellKitExampleSection(
          title: nil,
          rows: [
            row(FKCellDisclosureCell.self, title: "Privacy Policy") {
              $0.configure(with: FKCellDisclosureRow(id: "privacy", title: "Privacy Policy"))
            },
            FKCellKitExampleSampleData.sampleCellRegulatoryCell(),
          ]
        ),
      ]
    )
  }

  static func settingsTransferReset() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Transfer or Reset",
      sections: [
        FKCellKitExampleSection(
          title: "Prepare",
          rows: [
            row(FKCellFeatureCardCell.self, title: "Quick Start") {
              $0.configure(with: FKCellFeatureCardRow(
                id: "quickstart",
                configuration: FKCellFeatureCardConfiguration(
                  icon: FKCellIconContent(symbolName: "arrow.triangle.2.circlepath"),
                  title: "Prepare for New iPhone",
                  description: "Move data to your next device with minimal downtime.",
                  primaryAction: FKCellActionLink(title: "Get Started")
                )
              ))
            },
            row(FKCellValueDisclosureCell.self, title: "Get Started") {
              $0.configure(with: FKCellValueDisclosureRow(id: "start", title: "Get Started", value: ""))
            },
          ]
        ),
      ]
    )
  }

  // MARK: - Forms (#10–#18)

  static func formLoginRegister() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Login & Register",
      sections: [
        FKCellKitExampleSection(
          title: "Sign In",
          rows: [
            row(FKFormCellTextFieldCell.self, title: "Email") {
              $0.configure(with: FKFormTextFieldRow(id: "email", layout: .underline, label: "Email", placeholder: "name@company.com"))
            },
            row(FKFormCellTextFieldCell.self, title: "Password") {
              $0.configure(with: FKFormPasswordRow(id: "password", layout: .underline, label: "Password", placeholder: "Required"))
            },
            row(FKFormCellAgreementCell.self, title: "Terms") {
              $0.configure(with: FKFormAgreementRow(
                id: "terms",
                text: "I agree to the Terms of Service and Privacy Policy.",
                linkRanges: [
                  FKCellLinkRange(location: 14, length: 20, url: URL(string: "https://example.com/terms")!),
                  FKCellLinkRange(location: 39, length: 14, url: URL(string: "https://example.com/privacy")!),
                ]
              ))
            },
            row(FKFormCellPrimaryButtonCell.self, title: "Submit") {
              $0.configure(with: FKFormPrimaryButtonRow(id: "signin", title: "Sign In"))
            },
          ]
        ),
        FKCellKitExampleSection(
          title: "Social",
          rows: [
            FKCellKitExampleSampleData.sampleFormCellSocialAccountCell(),
          ]
        ),
      ]
    )
  }

  static func formProfileEdit() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Profile Edit",
      sections: [
        FKCellKitExampleSection(
          title: "Basics",
          rows: [
            row(FKFormCellTextFieldCell.self, title: "Display Name") {
              $0.configure(with: FKFormTextFieldRow(id: "name", text: "Frank Chen", layout: .cardStacked, label: "Display Name"))
            },
            row(FKFormCellMultilineCell.self, title: "Bio") {
              $0.configure(with: FKFormMultilineRow(id: "bio", layout: .cardStacked, label: "Bio", placeholder: "Tell us about yourself"))
            },
            FKCellKitExampleSampleData.sampleFormCellMediaPickerCell(),
            row(FKFormCellDateCell.self, title: "Birthday") {
              $0.configure(with: FKFormDateRow(id: "birthday", layout: .cardStacked, label: "Birthday"))
            },
          ]
        ),
      ]
    )
  }

  static func formMaterialUnderline() -> UIViewController {
    makeFormLayoutGallery(title: "Material Underline", layout: .underline)
  }

  static func formCardStacked() -> UIViewController {
    makeFormLayoutGallery(title: "Card Stacked", layout: .cardStacked)
  }

  static func formCardInline() -> UIViewController {
    makeFormLayoutGallery(title: "Card Inline", layout: .cardInline)
  }

  static func formContactSocial() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Contact & Social",
      sections: [
        FKCellKitExampleSection(
          title: "Contact",
          rows: [
            row(FKFormCellPhoneCell.self, title: "Phone") {
              $0.configure(with: FKFormPhoneRow(id: "phone", layout: .iconUnderline, label: "Mobile"))
            },
            FKCellKitExampleSampleData.sampleFormCellSocialAccountCell(),
            row(FKFormCellTextFieldCell.self, title: "Website") {
              $0.configure(with: FKFormTextFieldRow(id: "web", layout: .iconUnderline, label: "Website", placeholder: "https://"))
            },
          ]
        ),
      ]
    )
  }

  static func formEnterpriseInline() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Enterprise Inline",
      sections: [
        FKCellKitExampleSection(
          title: "Employee",
          rows: [
            row(FKFormCellTextFieldCell.self, title: "Employee ID") {
              $0.configure(with: FKFormTextFieldRow(id: "emp", layout: .inlineLabel, label: "Employee ID"))
            },
            row(FKFormCellPickerCell.self, title: "Department") {
              $0.configure(with: FKFormPickerRow(
                id: "dept",
                value: "Engineering",
                configuration: FKFormCellPickerConfiguration(layout: .inlineLabel, label: "Department")
              ))
            },
            row(FKFormCellPickerCell.self, title: "Office") {
              $0.configure(with: FKFormPickerRow(
                id: "office",
                value: "San Francisco",
                configuration: FKFormCellPickerConfiguration(layout: .inlineLabel, label: "Office")
              ))
            },
            row(FKFormCellSMSCodeCell.self, title: "SMS") {
              $0.configure(with: FKFormSMSCodeRow(id: "sms", layout: .inlineLabel, label: "Verification Code"))
            },
          ]
        ),
      ]
    )
  }

  static func formInlineSearch() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Inline Search",
      sections: [
        FKCellKitExampleSection(
          title: "Search Styles",
          rows: [
            row(FKFormCellSearchCell.self, title: "Capsule Filter") {
              $0.configure(with: FKFormSearchRow(
                id: "capsule",
                text: "",
                configuration: FKFormCellSearchConfiguration(style: .capsule, placeholder: "Search")
              ))
            },
            row(FKFormCellSearchCell.self, title: "Rounded + Button") {
              $0.configure(with: FKFormSearchRow(
                id: "rounded",
                text: "",
                configuration: FKFormCellSearchConfiguration(style: .roundedWithButton, placeholder: "Search products")
              ))
            },
            row(FKFormCellSearchCell.self, title: "Category Prefix") {
              $0.configure(with: FKFormSearchRow(
                id: "prefix",
                text: "",
                configuration: FKFormCellSearchConfiguration(style: .prefixCategory(title: "Movies"))
              ))
            },
            row(FKFormCellSearchCell.self, title: "Voice Icon") {
              $0.configure(with: FKFormSearchRow(
                id: "voice",
                text: "",
                configuration: FKFormCellSearchConfiguration(style: .withVoiceIcon, placeholder: "Search")
              ))
            },
            FKCellKitExampleSampleData.sampleFormCellFilterChipsCell(),
            FKCellKitExampleSampleData.sampleCellRecentSearchCell(),
            FKCellKitExampleSampleData.sampleCellSearchResultCell(),
          ]
        ),
      ]
    )
  }

  // MARK: - Display (#19–#24)

  static func messagesInbox() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Messages Inbox",
      sections: [
        FKCellKitExampleSection(
          title: "Today",
          rows: [
            FKCellKitExampleSampleData.sampleCellConversationCell(),
            FKCellKitExampleSampleData.sampleCellConversationCell(),
          ]
        ),
      ]
    )
  }

  static func commerceCheckout() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Checkout",
      sections: [
        FKCellKitExampleSection(
          title: "Order",
          rows: [
            FKCellKitExampleSampleData.sampleCellProductCell(),
            FKCellKitExampleSampleData.sampleCellPaymentMethodCell(),
          ]
        ),
      ]
    )
  }

  static func faqExpandable() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "FAQ",
      sections: [
        FKCellKitExampleSection(
          title: "Common Questions",
          rows: [
            FKCellKitExampleSampleData.sampleCellExpandableCell(),
            FKCellKitExampleSampleData.sampleCellExpandableCell(),
          ]
        ),
      ]
    )
  }

  static func listSortFilter() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Sort & Filter",
      sections: [
        FKCellKitExampleSection(
          title: nil,
          rows: [
            FKCellKitExampleSampleData.sampleCellSortFilterBarCell(),
            FKCellKitExampleSampleData.sampleCellFilterSummaryCell(),
          ]
        ),
      ]
    )
  }

  // MARK: - Phase 6 (#22–#27)

  static func walletTransactions() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Wallet Transactions",
      sections: [
        FKCellKitExampleSection(
          title: "Recent",
          rows: [
            FKCellKitExampleSampleData.sampleCellTransactionCell(),
            FKCellKitExampleSampleData.sampleCellPaymentMethodCell(),
          ]
        ),
      ]
    )
  }

  static func mediaPlaylist() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Media Playlist",
      sections: [
        FKCellKitExampleSection(
          title: "Now Playing",
          rows: [
            FKCellKitExampleSampleData.sampleCellNowPlayingCell(),
            FKCellKitExampleSampleData.sampleCellPlayableMediaCell(),
            FKCellKitExampleSampleData.sampleCellAudioTrackCell(),
          ]
        ),
      ]
    )
  }

  static func taskAndCheckbox() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Tasks & Checkbox",
      sections: [
        FKCellKitExampleSection(
          title: "Today",
          rows: [
            FKCellKitExampleSampleData.sampleCellTaskCell(),
            row(FKCellCheckboxCell.self, title: "Checkbox") {
              $0.configure(with: FKCellCheckboxRow(
                id: "task2",
                configuration: FKCellCheckboxConfiguration(title: "Review pull request", isChecked: false)
              ))
            },
            FKCellKitExampleSampleData.sampleCellSliderCell(),
          ]
        ),
      ]
    )
  }

  static func formExtendedFields() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "Extended Form Fields",
      sections: [
        FKCellKitExampleSection(
          title: "Advanced Inputs",
          rows: [
            FKCellKitExampleSampleData.sampleFormCellRangeCell(),
            FKCellKitExampleSampleData.sampleFormCellColorCell(),
            FKCellKitExampleSampleData.sampleFormCellRichTextEditorCell(),
            FKCellKitExampleSampleData.sampleFormCellMediaGridCell(),
            FKCellKitExampleSampleData.sampleFormCellMapRadiusCell(),
          ]
        ),
      ]
    )
  }

  static func surveyNPS() -> UIViewController {
    FKCellKitExampleTableViewController(
      title: "NPS Survey",
      sections: [
        FKCellKitExampleSection(
          title: "Feedback",
          rows: [
            FKCellKitExampleSampleData.sampleFormCellNPSScaleCell(),
            FKCellKitExampleSampleData.sampleCellPollResultCell(),
          ]
        ),
      ]
    )
  }

  // MARK: - Helpers

  private static func makeFormLayoutGallery(title: String, layout: FKFormCellLayout) -> UIViewController {
    FKCellKitExampleTableViewController(
      title: title,
      sections: [
        FKCellKitExampleSection(
          title: "Text",
          rows: [
            row(FKFormCellTextFieldCell.self, title: "Text Field") {
              $0.configure(with: FKFormTextFieldRow(id: "text", layout: layout, label: "Full Name", placeholder: "Required"))
            },
            row(FKFormCellTextFieldCell.self, title: "Password") {
              $0.configure(with: FKFormPasswordRow(id: "pass", layout: layout, label: "Password"))
            },
          ]
        ),
        FKCellKitExampleSection(
          title: "Pickers",
          rows: [
            row(FKFormCellPickerCell.self, title: "Picker") {
              $0.configure(with: FKFormPickerRow(
                id: "picker",
                value: "United States",
                configuration: FKFormCellPickerConfiguration(layout: layout, label: "Country")
              ))
            },
            row(FKFormCellDateCell.self, title: "Date") {
              $0.configure(with: FKFormDateRow(id: "date", layout: layout, label: "Start Date"))
            },
          ]
        ),
      ]
    )
  }

  private static func row<Cell: FKCellReusable>(
    _ type: Cell.Type,
    title: String,
    configure: @MainActor @escaping (Cell) -> Void
  ) -> FKCellKitExampleRow {
    FKCellKitExampleRow.make(type, title: title, configure: configure)
  }
}
