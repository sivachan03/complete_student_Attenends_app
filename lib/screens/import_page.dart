import 'package:flutter/material.dart';
import 'package:student_attendence/models/student.dart';
import 'package:student_attendence/services/excel_import.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_Service.dart';

class ImportScreen extends StatefulWidget {
  @override
  _ImportScreenState createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final FirebaseService _fs = FirebaseService();
  bool _loading = false;
  String _status = '';

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _status = 'Picking file...';
    });
    final parsed = await ExcelImport.pickAndParseExcel();
    if (parsed == null) {
      setState(() {
        _loading = false;
        _status = 'No file chosen.';
      });
      return;
    }

    setState(() {
      _status = 'Uploading ${parsed.length} students...';
    });

    final uuid = Uuid();
    int added = 0;

    for (final row in parsed) {
      final id = uuid.v4();
      final s = Student(
        id: id,
        studentName: row['student_name'] ?? '',
        rollNumber: row['roll_number'] ?? '',
        courseName: row['course_name'] ?? '',
      );
      await _fs.addStudent(s);
      added++;
    }

    setState(() {
      _loading = false;
      _status = 'Imported $added students';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Students')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Import Excel with columns: Student Name, Roll Number, Course Name',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _import,
              child: Text('Pick & Import Excel'),
            ),
            SizedBox(height: 16),
            if (_status.isNotEmpty) Text(_status),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go to Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
