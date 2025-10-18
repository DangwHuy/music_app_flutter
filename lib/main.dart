import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lan2tesst/firebase_options.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ViewlyApp());
}

class ViewlyApp extends StatelessWidget {
  const ViewlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viewdly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
