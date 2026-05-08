import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  GoogleSignInService({
    List<String> scopes = const ['email', 'profile'],
    String? serverClientId,
  }) : _googleSignIn = GoogleSignIn(
    scopes: scopes,
    // serverClientId: serverClientId,
  );

  Future<String?> signIn() async {
    try {
      // Force account picker by signing out first
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return googleAuth.idToken;
    } catch (e) {
      print('GoogleSignInService error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAccount?> get currentUser async => _googleSignIn.currentUser;
}