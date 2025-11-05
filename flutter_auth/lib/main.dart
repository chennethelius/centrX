import 'package:flutter/material.dart';
//import 'pages/old_login_page.dart';
import 'components/app_shell.dart';
import 'login/new_login_page.dart';
import 'pages/club_page.dart';
import 'pages/teacher_page.dart';
//import 'pages/club_page.dart';

import 'package:flutter_auth/services/auth_service.dart';
// import 'package:flutter_auth/services/canvas_background_sync.dart'; // COMMENTED OUT - Canvas integration disabled
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getUserRole(String uid) async {
    final firestore = AuthService().firestore;
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) return userDoc.data()?['role'] as String?;
    final clubDoc = await firestore.collection('clubs').doc(uid).get();
    if (clubDoc.exists) return clubDoc.data()?['role'] as String?;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    
    // COMMENTED OUT - Canvas integration disabled
    // Trigger background Canvas sync if user is logged in
    // if (user != null) {
    //   CanvasBackgroundSync.checkAndSyncIfNeeded().catchError((_) {});
    // }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: user == null
          ? const NewLoginPage()
          : FutureBuilder<String?>(
              future: _getUserRole(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const NewLoginPage();
                }
                final role = snapshot.data;
                if (role == 'student') return const AppShell();
                if (role == 'teacher') return const TeacherPage();
                if (role == 'club') return const ClubPage();
                // fallback to login if role is missing
                return const NewLoginPage();
              },
            ),
    );
  }
}

