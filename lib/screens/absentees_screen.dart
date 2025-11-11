import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_Service.dart';
import '../models/student.dart';

class AbsenteesScreen extends StatefulWidget {
  final DateTime date;
  const AbsenteesScreen({super.key, required this.date});

  @override
  State<AbsenteesScreen> createState() => _AbsenteesScreenState();
}

class _AbsenteesScreenState extends State<AbsenteesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _fs = FirebaseService();
  bool loading = true;

  // ✅ Separate data lists for each tab
  List<Map<String, dynamic>> absentees = [];
  List<Map<String, dynamic>> absentEveryDay = [];
  List<Map<String, dynamic>> presentEveryDay = [];

  late DateTime fromDate;
  late DateTime toDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    fromDate = widget.date;
    toDate = widget.date;

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Load only when tab index actually changes
      if (!_tabController.indexIsChanging) {
        _loadReport();
      }
    });

    _loadReport(); // initial load for default tab (Absentees)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -----------------------
  // 🔹 Date Pickers
  // -----------------------
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => fromDate = picked);
      _reloadAllTabs();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => toDate = picked);
      _reloadAllTabs();
    }
  }

  // -----------------------
  // 🔹 Load Reports per Tab
  // -----------------------
  Future<void> _loadReport() async {
    setState(() => loading = true);
    try {
      final index = _tabController.index;
      if (index == 0) {
        absentees = await _fs.getAbsencesBetween(fromDate, toDate);
      } else if (index == 1) {
        final students = await _fs.getStudentsAbsentEveryDay(fromDate, toDate);
        absentEveryDay = students
            .map(
              (s) => {
                'student_name': s.studentName,
                'roll_number': s.rollNumber,
              },
            )
            .toList();
      } else if (index == 2) {
        final students = await _fs.getStudentsPresentEveryDay(fromDate, toDate);
        presentEveryDay = students
            .map(
              (s) => {
                'student_name': s.studentName,
                'roll_number': s.rollNumber,
              },
            )
            .toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  // Reloads all lists when date range changes
  Future<void> _reloadAllTabs() async {
    setState(() {
      loading = true;
      absentees.clear();
      absentEveryDay.clear();
      presentEveryDay.clear();
    });
    await _loadReport();
  }

  // -----------------------
  // 🔹 Undo Absence
  // -----------------------
  Future<void> _undoAbsence(Map<String, dynamic> absence) async {
    if (absence['id'] == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Absence'),
        content: Text(
          'Remove absence for ${absence['student_name']} (Roll: ${absence['roll_number']})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _fs.deleteAbsence(absence['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${absence['student_name']}\'s absence removed'),
          ),
        );
        _loadReport();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // -----------------------
  // 🔹 Build ListView Widget
  // -----------------------
  Widget _buildListView(List<Map<String, dynamic>> data, bool canDelete) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : data.isEmpty
        ? Center(
            child: Text(
              'No records from ${DateFormat('yyyy-MM-dd').format(fromDate)} '
              'to ${DateFormat('yyyy-MM-dd').format(toDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadReport,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                final a = data[i];
                final dateTime = a['date_time'] != null
                    ? (a['date_time'] as Timestamp).toDate()
                    : null;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: canDelete
                          ? Colors.redAccent
                          : Colors.lightBlueAccent,
                      child: Text(
                        (a['student_name']?.isNotEmpty ?? false)
                            ? a['student_name'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(a['student_name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roll: ${a['roll_number'] ?? 'N/A'}'),
                        if (dateTime != null)
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(dateTime)}',
                          ),
                      ],
                    ),
                    trailing: canDelete
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _undoAbsence(a),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
  }

  // -----------------------
  // 🔹 Build UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.lightBlueAccent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Absentees'),
            Tab(text: 'Absent Everyday'),
            Tab(text: 'Present Everyday'),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text('From: '),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _pickFromDate,
              ),
            ],
          ),
          Row(
            children: [
              const Text('To: '),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _pickToDate,
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(absentees, true),
          _buildListView(absentEveryDay, false),
          _buildListView(presentEveryDay, false),
        ],
      ),
    );
  }
}
