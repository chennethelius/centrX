import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // instance of auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get current user
  User? getCurrentUser() {
  return _firebaseAuth.currentUser;
}

  // sign out
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }
    
  }



