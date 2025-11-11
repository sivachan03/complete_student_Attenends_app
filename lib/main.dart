import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_attendence/screens/attendance_screen.dart';
import 'package:student_attendence/screens/home_page.dart';
import 'screens/import_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Attendance',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
