import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Central service handling Firebase and Google Sign-In authentication logic
class AuthService {
  // FirebaseAuth instance for Firebase operations
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // GoogleSignIn instance for Google authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Initializes Google Sign-In for silent authentication if possible.
  /// Call once in initState(), e.g., in LoginPage.initState().
  Future<void> initializeGoogleSignIn({
    String? clientId,
    String? serverClientId,
    void Function(GoogleSignInAuthenticationEvent)? onAuthEvent,
    void Function(Object)? onAuthError,
  }) async {
    // Start initialization without awaiting to avoid blocking UI
    _googleSignIn
        .initialize(clientId: clientId, serverClientId: serverClientId)
        .then((_) {
      if (onAuthEvent != null) {
        // Listen for sign-in and sign-out events
        _googleSignIn.authenticationEvents
            .listen(onAuthEvent)
            .onError(onAuthError ?? (e) {});
      }
      // Attempt silent sign-in if credentials are cached (no UI)
      _googleSignIn.attemptLightweightAuthentication();
    });
  }

  /// Starts the interactive Google Sign-In flow.
  /// Must be called from a user gesture (e.g., button press).
  Future<UserCredential?> authenticateWithGoogle() async {
    try {
      // Check if interactive sign-in is supported on this platform
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Interactive Google Sign-In not supported.');
      }

      // Launch the full Google Sign-In UI
      await _googleSignIn.authenticate();

      // Wait for the next "signedIn" event
      final event = await _googleSignIn.authenticationEvents.firstWhere(
        (e) => e is GoogleSignInAuthenticationEventSignIn,
      ) as GoogleSignInAuthenticationEventSignIn;

      // Get the signed-in Google account
      final account = event.user;

      // Retrieve OAuth tokens (access and ID) synchronously
      final googleAuth = account.authentication;

      // Create a new Firebase credential using Google tokens
      final credential = GoogleAuthProvider.credential(
        //accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print('❌ Google sign-in error: $e');
      return null;
    }
  }

  /// Signs out from both Google and Firebase.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// Returns the currently signed-in Firebase user, if any.
  User? get currentUser => _firebaseAuth.currentUser;
}
