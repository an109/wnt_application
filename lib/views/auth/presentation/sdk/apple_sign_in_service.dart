import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result of a successful Apple Sign In. Apple only returns name/email on the
/// very first authorization for a given Apple ID, so they are nullable.
class AppleSignInResult {
  final String identityToken;
  final String? firstName;
  final String? lastName;
  final String? email;

  AppleSignInResult({
    required this.identityToken,
    this.firstName,
    this.lastName,
    this.email,
  });
}

class AppleSignInService {
  /// Whether Sign in with Apple is available on this device/platform.
  Future<bool> isAvailable() => SignInWithApple.isAvailable();

  /// Triggers the native Apple Sign In flow and returns the identity token
  /// (+ optional name/email). Returns null if no identity token is produced.
  Future<AppleSignInResult?> signIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    return AppleSignInResult(
      identityToken: token,
      firstName: credential.givenName,
      lastName: credential.familyName,
      email: credential.email,
    );
  }
}
