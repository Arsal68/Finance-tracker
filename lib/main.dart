import 'package:flutter/material.dart';
import 'package:finance_tracker/dashboard.dart';
import 'package:finance_tracker/signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:finance_tracker/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Raleway',
            color: Color.fromARGB(255, 234, 0, 255),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Raleway',
            color: Color.fromARGB(255, 251, 0, 255),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Raleway',
            color: Color.fromARGB(255, 255, 0, 225),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SignupPage(),
    );
  }
}
