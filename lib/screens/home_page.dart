import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:student_attendence/screens/absentees_screen.dart';
import 'package:student_attendence/screens/attendance_screen.dart';
import 'package:student_attendence/screens/import_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 20, title: Text("EduTrack")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Expanded(
                child: Container(
                  width: 400,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: FractionalOffset(0.0, 0.0),
                      end: Alignment.bottomRight,
                      tileMode: TileMode.clamp,
                      colors: [
                        Color(0xff99cdf8),
                        Color(0xff5fa3db),
                        Color(0xff79a5ef),
                        Color(0xff369aea),
                      ],
                      stops: [0.1, 0.5, 0.7, 0.9],
                    ),
                    // color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 8,
                        spreadRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(Icons.thumb_up, size: 28, color: Colors.white),
                            Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          "Today' Task take CS-101 Attendance \n 80 students Enrolled",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Custome Container here
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    left: 15.0,
                    right: 15,
                  ),
                  child: CustomeContainer(
                    iconColor: Colors.greenAccent,
                    conColor: Colors.white,
                    size: 32,
                    title: "Take Attendence",
                    subtitle: "Quick mark Student present today",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AttendanceScreen()),
                      );
                    },
                    icon:
                        Icons.calendar_month, // 👈 Here you pass the icon data
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 15.0,
                    right: 15,
                  ),
                  child: CustomeContainer(
                    iconColor: Colors.purpleAccent,
                    conColor: Colors.white,
                    size: 32,
                    title: "Manage Students",
                    subtitle: "View Add Or import Student Data",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ImportScreen()),
                      );
                    },
                    icon: Icons.person, // 👈 Here you pass the icon data
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 15.0,
                    right: 15,
                  ),
                  child: CustomeContainer(
                    iconColor: Colors.red,
                    conColor: Colors.white,
                    size: 32,
                    title: "View Reports",
                    subtitle: "Check attendence histroy and sumnaries",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AbsenteesScreen(date: DateTime.now()),
                        ),
                      );
                    },
                    icon: Icons.chat_rounded, // 👈 Here you pass the icon data
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//
class CustomeContainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color conColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double size;
  const CustomeContainer({
    Key? key,
    required this.icon,
    required this.size,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.conColor,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: conColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 8,
              spreadRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: size),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
