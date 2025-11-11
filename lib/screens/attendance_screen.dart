import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../services/firebase_Service.dart';
import 'absentees_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseService _fs = FirebaseService();
  List<Student> students = [];
  Map<String, bool> isAbsent = {}; // studentId -> true if absent
  int currentIndex = 0;
  bool loading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => loading = true);
    students = await _fs.getAllStudents();
    await _loadAbsenteesForDate();
    setState(() => loading = false);
  }

  Future<void> _loadAbsenteesForDate() async {
    final absentees = await _fs.getAbsenteesForDate(selectedDate);
    isAbsent = {for (var s in students) s.id: false};
    for (var absence in absentees) {
      isAbsent[absence['student_id']] = true;
    }
  }

  void _toggleAbsent(String id) async {
    final wasAbsent = isAbsent[id] ?? false;
    final newAbsent = !wasAbsent;
    setState(() {
      isAbsent[id] = newAbsent;
    });
    final student = students.firstWhere((s) => s.id == id);
    if (newAbsent) {
      await _fs.recordAbsence(student.rollNumber, selectedDate);
    } else {
      await _fs.deleteAbsenceByStudentAndDate(student.id, selectedDate);
    }
  }

  Future<void> _markAndNext(bool markAbsent) async {
    if (currentIndex >= students.length) return;
    final student = students[currentIndex];

    if (markAbsent) {
      // await _fs.recordAbsence(student.id, DateTime.now());
      await _fs.recordAbsence(student.rollNumber, selectedDate);
      isAbsent[student.id] = true;
    } else {
      isAbsent[student.id] = false;
    }

    setState(() {
      currentIndex = (currentIndex + 1).clamp(0, students.length);
    });
  }

  Widget _buildRow(int index, Student s) {
    final bool absent = isAbsent[s.id] ?? false;
    final bool isCurrent = index == currentIndex;

    final Color? rowColor = isCurrent
        ? Colors.yellow.shade100
        : absent
        ? Colors.red.shade100
        : null;

    return Container(
      color: rowColor,
      child: ListTile(
        key: ValueKey(s.id),
        leading: Text('${index + 1}'),
        title: GestureDetector(
          onTap: () => setState(() => currentIndex = index),
          child: Text(s.studentName),
        ),
        subtitle: Text('Roll: ${s.rollNumber} | ${s.courseName}'),
        trailing: Switch(value: absent, onChanged: (_) => _toggleAbsent(s.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                        currentIndex = 0;
                      });
                      await _loadAbsenteesForDate();
                      setState(() {}); // ✅ Refresh UI
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (_, i) => _buildRow(i, students[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentIndex < students.length
                        ? () => _markAndNext(false)
                        : null,
                    child: const Text('Present'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: currentIndex < students.length
                        ? () => _markAndNext(true)
                        : null,
                    child: const Text('Absent'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.purple,

        elevation: 4,
        onPressed: () {
          Fluttertoast.showToast(
            msg: "This is Center Short Toast",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blueAccent,
            textColor: Colors.black26,
            fontSize: 16.0,
          );
          Navigator.pop(context);
        },
        child: Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
