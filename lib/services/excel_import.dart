import 'dart:io';
import 'package:excel/excel.dart';

import 'package:file_picker/file_picker.dart';
class ExcelImport {
  /// Opens file picker and returns list of maps for students
  static Future<List<Map<String, String>>?> pickAndParseExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null) return null;
    final bytes = result.files.first.bytes;
    // If bytes are null (on Android), read file path
    final path = result.files.first.path;
    List<int> fileBytes;
    if (bytes != null) {
      fileBytes = bytes;
    } else if (path != null) {
      fileBytes = File(path).readAsBytesSync();
    } else {
      return null;
    }
    final excel = Excel.decodeBytes(fileBytes);
    List<Map<String, String>> rows = [];

    // Assume first sheet
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return rows;

    // Expect header row: Student Name, Roll Number, Course Name
    final header = sheet.rows.first
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList();

    int nameIdx = header.indexWhere((h) => h.toLowerCase().contains('name'));
    int rollIdx = header.indexWhere((h) => h.toLowerCase().contains('roll'));
    int courseIdx = header.indexWhere(
      (h) => h.toLowerCase().contains('course'),
    );
    for (int i = 1; i < sheet.rows.length; i++) {
      final r = sheet.rows[i];
      if (r.every((c) => c == null || (c.value ?? '').toString().trim() == ''))
        continue; // skip empty rows
      final name = (nameIdx >= 0 && nameIdx < r.length)
          ? (r[nameIdx]?.value?.toString() ?? '')
          : '';
      final roll = (rollIdx >= 0 && rollIdx < r.length)
          ? (r[rollIdx]?.value?.toString() ?? '')
          : '';
      final course = (courseIdx >= 0 && courseIdx < r.length)
          ? (r[courseIdx]?.value?.toString() ?? '')
          : '';
      rows.add({
        'student_name': name.trim(),
        'roll_number': roll.trim(),
        'course_name': course.trim(),
      });
    }
    return rows;
  }
}
