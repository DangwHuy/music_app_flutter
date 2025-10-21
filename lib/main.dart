import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lan2tesst/firebase_options.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';
import 'package:lan2tesst/ui/home/home.dart';

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
      title: 'Viewly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Wrapper(), // Use a Wrapper to handle auth state
    );
  }
}

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _initMessaging(user);
      }
    });
  }

  Future<void> _initMessaging(User user) async {
    final messaging = FirebaseMessaging.instance;
    
    // Request permission
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the FCM token
    final token = await messaging.getToken();
    if (token == null) return;

    // Save the token to the user's document in Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MusicHomePage(); // User is logged in
        }
        return const AuthScreen(); // User is not logged in
      },
    );
  }
}
