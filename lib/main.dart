import 'package:flutter/material.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const SurveyApp());
}

class SurveyApp extends StatelessWidget {
  const SurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field3D Traverse Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
        hintColor: Colors.amberAccent,
      ),
      home: const TraverseDashboard(),
    );
  }
}