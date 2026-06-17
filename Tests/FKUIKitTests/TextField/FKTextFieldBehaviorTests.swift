import FKUIKit
import XCTest

@MainActor
final class FKTextFieldBehaviorTests: FKUIKitTestCase {
  func testSetTextAppliesPhoneFormattingAndPreservesRawDigits() {
    var rule = FKTextFieldInputRule(formatType: .phoneNumber)
    rule.maxLength = 11
    let field = FKTextField(configuration: FKTextFieldConfiguration(inputRule: rule))

    field.fk_setText("13800138000")

    XCTAssertEqual(field.rawText, "13800138000")
    XCTAssertEqual(field.text?.filter(\.isNumber).count, 11)
    XCTAssertNotEqual(field.text, field.rawText)
  }

  func testInvalidPhoneInputMarksValidationResultInvalidOnChange() {
    var configuration = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .phoneNumber))
    configuration.validationPolicy.trigger = .onChange
    configuration.validationPolicy.debounceInterval = 0
    configuration.validationPolicy.ignoresEmptyInput = true
    let field = FKTextField(configuration: configuration)

    field.fk_setText("12345")

    XCTAssertFalse(field.validationResult.isValid)
    XCTAssertEqual(field.status, .error)
  }

  func testVerificationCodeCompletionCallbackFiresAtFixedLength() {
    var rule = FKTextFieldInputRule(formatType: .verificationCode(length: 6, allowsAlphabet: false))
    let field = FKTextField(configuration: FKTextFieldConfiguration(inputRule: rule))
    var completedValue: String?
    field.onInputCompleted = { completedValue = $0 }

    field.fk_setText("123456")

    XCTAssertEqual(completedValue, "123456")
    XCTAssertEqual(field.rawText, "123456")
  }

  func testNumericFormatStripsNonDigitCharacters() {
    let field = FKTextField(
      configuration: FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .numeric))
    )

    field.fk_setText("12a3b4")

    XCTAssertEqual(field.rawText, "1234")
  }
}
