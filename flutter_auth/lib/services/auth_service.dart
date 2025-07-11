import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified AuthService that works on mobile and web
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        //accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // make sure we have a user
      final user = userCredential.user;
      if (user == null) return null;

    // add user to firestore user collection
      final userDoc = _firestore.collection('users').doc(user.uid);

      // parses users name into first and last
      final fullName = user.displayName ?? '';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // adds user to firestore collection users
      await userDoc.set({
        'firstName':     firstName,
        'lastName':      lastName,
        'email':         user.email       ?? '',
        'role':          'student',                  
        'pointsBalance': 0,                          
        'createdAt':     FieldValue.serverTimestamp(),
      });


      return userCredential.user;
    } catch (e) {
      //print('❌ Google sign-in error: $e');
      return null;
    }
  }

  /// Signs out from both Google and Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect();
    await _auth.signOut();
  }

  /// Current Firebase user, if signed in
  User? get currentUser => _auth.currentUser;
}
