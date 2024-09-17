import 'package:chatapplication/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: "AIzaSyDOejxCRCQ44y_usVnVp7UzBJ6N894w8xI",
    appId: "1:202598003577:android:2fba0b617677499b50b5a8",
    messagingSenderId: "202598003577",
    projectId: "chatapp-20ae5",
    storageBucket: "gs://chatapp-20ae5.appspot.com",
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _setOnlineStatusOnLogin();
  }

  void _setOnlineStatusOnLogin() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateUserStatus(user.uid, 'online');
      } else {
        _updateUserStatus(_auth.currentUser?.uid ?? '', 'offline');
      }
    });
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    if (userId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'status': status});
    }
  }

  @override
  void dispose() {
    if (_auth.currentUser != null) {
      _updateUserStatus(_auth.currentUser!.uid, 'offline');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
