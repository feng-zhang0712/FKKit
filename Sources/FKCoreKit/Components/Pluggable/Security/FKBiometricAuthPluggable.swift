/// Pluggable device-owner authentication boundary.
///
/// Conform with ``FKBiometricAuth`` in production or ``FKMockBiometricAuthenticator`` in tests.
/// Protocol definition: ``FKBiometricAuthenticating`` in `Components/BiometricAuth/Public/`.
public typealias FKBiometricAuthenticatingPluggable = FKBiometricAuthenticating
