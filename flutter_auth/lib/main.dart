import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'components/app_shell.dart';

import 'package:flutter_auth/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('hello');
     final isLoggedIn = AuthService().currentUser != null;
     print('pass');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'centrX',
      // if user not logged in, direct to login page, but if user is logged in, go to appshell
      home: isLoggedIn ? const LoginPage() : const AppShell(),
      
    );
  }
}

