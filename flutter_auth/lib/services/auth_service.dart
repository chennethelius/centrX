import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified AuthService that works on mobile and web
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  /// Teacher authentication flow - checks teachers_dir and creates user account
  Future<User?> teacherLogin() async {
    try {
      // 1️⃣ Google authentication (same as student flow)
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // 2️⃣ Check if email exists in teachers_dir
      final email = (user.email ?? '').toLowerCase();
      final teacherQuery = await _firestore
          .collection('teachers_dir')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (teacherQuery.docs.isEmpty) {
        // Not a teacher - sign out and return null
        await signOut();
        return null;
      }

      // 3️⃣ Get teacher data from directory
      final teacherData = teacherQuery.docs.first.data();
      final fullName = teacherData['fullName'] ?? '';
      
      // Parse name and remove titles
      final cleanName = fullName
          .replaceAll(RegExp(r',?\s*(Ph\.?D\.?|Dr\.?|M\.?D\.?)'), '')
          .trim();
      final nameParts = cleanName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // 4️⃣ Create/update user account with teacher role
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': 'teacher',
        'teacherId': teacherQuery.docs.first.id,
        'department': teacherData['department'] ?? '',
        'school': teacherData['school'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return user;
    } catch (e) {
      debugPrint('❌ Teacher login error: $e');
      return null;
    }
  }

  /// TEST ONLY: Manual teacher login with email input (bypasses Google Sign-In)
  /// Returns a Firebase [User] on success or null if not a teacher
  Future<User?> testTeacherLogin(String testEmail) async {
    try {
      debugPrint('🧪 TEST: Starting manual teacher login for: $testEmail');
      
      // 1️⃣ Check if email exists in teachers_dir
      final email = testEmail.toLowerCase().trim();
      final teacherQuery = await _firestore
          .collection('teachers_dir')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (teacherQuery.docs.isEmpty) {
        debugPrint('❌ TEST: Email not found in teachers_dir');
        return null;
      }

      // 2️⃣ Get teacher data from directory
      final teacherData = teacherQuery.docs.first.data();
      final fullName = teacherData['fullName'] ?? '';
      
      debugPrint('📊 TEST: Found teacher data - $fullName, Dept: ${teacherData['department']}');
      
      // Parse name and remove titles
      final cleanName = fullName
          .replaceAll(RegExp(r',?\s*(Ph\.?D\.?|Dr\.?|M\.?D\.?)'), '')
          .trim();
      final nameParts = cleanName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      debugPrint("$firstName, $lastName");

      // 3️⃣ Create a mock Firebase user for testing (using anonymous auth)
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) return null;

      debugPrint('👤 TEST: Created anonymous user, setting up teacher profile');

      // 4️⃣ Create/update user account with teacher role
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': 'teacher',
        'teacherId': teacherQuery.docs.first.id,
        'department': teacherData['department'] ?? '',
        'school': teacherData['school'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isTestAccount': true, // Mark as test account
      }, SetOptions(merge: true));

      debugPrint('✅ TEST: Teacher account created successfully');
      return user;
    } catch (e) {
      debugPrint('❌ TEST: Teacher login error: $e');
      return null;
    }
  }

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

      // check if user already exists in firestore
      final usersRef = _firestore.collection('users');
      final docRef   = usersRef.doc(user.uid);
      final snapshot = await docRef.get();

      // only writes in data if the user does not exist
      if (!snapshot.exists) {    
      // add user to firestore user collection
      final userDoc = _firestore.collection('users').doc(user.uid);

      // parses users name into first and last
      final fullName = user.displayName ?? '';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // adds user to firestore collection users
      await userDoc.set({
        'uid':           user.uid,
        'firstName':     firstName,
        'lastName':      lastName,
        'email':         user.email       ?? '',
        'role':          'student',                  
        'pointsBalance': 0,
        'events_registered': [],
        'clubs_joined': 0,
        'createdAt':     FieldValue.serverTimestamp(),
      });}


      return userCredential.user;
    } catch (e) {
      //print('❌ Google sign-in error: $e');
      return null;
    }
  }

/// Signs in a club by email+password. On first sign-in, initializes its
/// Firestore document under `clubs/{uid}` with default fields.
Future<User?> signInClubWithEmail({
  required String email,
  required String password,
}) async {
  try {
    // 1️⃣ Sign in via Firebase Auth
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCred.user;
    if (user == null) return null;

    // 2️⃣ Ensure the club Firestore doc exists
    final clubRef = _firestore.collection('clubs').doc(user.uid);
    final snap    = await clubRef.get();
    if (!snap.exists) {
      // Create with minimal defaults
      await clubRef.set({
        'uid':       user.uid,
        'email':     email,
        'password': password,
        'club_name': '',
        'createdAt': FieldValue.serverTimestamp(),
        'members_count': 0,
        'events_posted': 0,
        'role': 'club',
      });
    }

    return user;
  } on FirebaseAuthException {
    // propagate auth errors (wrong-password, user-not-found, etc.)
    rethrow;
  } catch (e, stack) {
    // unexpected errors
    debugPrint('Unexpected error in signInClubWithEmail: $e');
    debugPrint('$stack');
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


