import Foundation

public extension String {
  /// Returns whether the full string matches `pattern`.
  func fk_matches(
    pattern: String,
    options: NSRegularExpression.Options = []
  ) -> Bool {
    FKRegexMatching.isMatch(self, pattern: pattern, options: options)
  }

  /// Extracts all substrings matching `pattern`.
  func fk_extractMatches(
    pattern: String,
    options: NSRegularExpression.Options = []
  ) -> [String] {
    FKRegexMatching.matches(in: self, pattern: pattern, options: options)
  }

  /// Returns a copy with matches of `pattern` replaced by `template`.
  func fk_replacingMatches(
    pattern: String,
    with template: String,
    options: NSRegularExpression.Options = []
  ) -> String {
    FKRegexMatching.replacing(self, pattern: pattern, with: template, options: options)
  }

  /// Validates a mainland China mobile phone number.
  var fk_isValidPhone: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.phoneCN)
  }

  /// Validates an email address using the built-in pattern.
  var fk_isValidEmail: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.email)
  }

  /// Validates a Chinese ID card number shape.
  var fk_isValidIDCard: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.idCardCN)
  }

  /// Validates a strong password (letters, digits, symbol, minimum eight characters).
  var fk_isStrongPassword: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.passwordStrong)
  }

  /// Validates a numeric verification code with four to eight digits.
  var fk_isValidVerificationCode: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.verificationCode4To8)
  }

  /// Validates a Chinese license plate pattern.
  var fk_isValidLicensePlate: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.licensePlateCN)
  }

  /// Validates an HTTP or HTTPS URL pattern.
  var fk_isValidURLPattern: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.url)
  }

  /// Validates an IPv4 address.
  var fk_isValidIPv4: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.ipV4)
  }

  /// Validates a six-digit postal code.
  var fk_isValidPostalCode: Bool {
    fk_matches(pattern: FKRegexMatching.Pattern.postalCodeCN)
  }

  /// Validates a bank card number using regex and Luhn check.
  var fk_isValidBankCard: Bool {
    FKRegexMatching.isValidBankCard(self)
  }
}
