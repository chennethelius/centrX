import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Simplified AuthService that works on mobile and web
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Triggers Google Sign-In flow
  /// Returns a Firebase [User] on success or null on cancel/error
  Future<User?> authenticateWithGoogle() async {
    try {
      // On web, use GoogleSignIn popup; on mobile, use standard flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        // User cancelled sign-in
        return null;
      }

      // Obtain the auth details (tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        //accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      //print('❌ Google sign-in error: $e');
      return null;
    }
  }

  /// Signs out from both Google and Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Current Firebase user, if signed in
  User? get currentUser => _auth.currentUser;
}
