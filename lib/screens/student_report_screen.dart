import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentReportScreen extends StatefulWidget {
  final String reportType; // 'Midterm' or 'Final'

  const StudentReportScreen({
    super.key,
    required this.reportType,
  });

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _tasksController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReport();
  }

  @override
  void dispose() {
    _tasksController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReport() async {
    setState(() => _isLoading = true);
    try {
      final studentId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('student_reports')
          .select('tasks_completed, skills_acquired')
          .eq('student_id', studentId)
          .eq('report_type', widget.reportType)
          .maybeSingle();
      
      if (response != null) {
        _tasksController.text = response['tasks_completed'] as String? ?? '';
        _skillsController.text = response['skills_acquired'] as String? ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveReport() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    try {
      final studentId = _supabase.auth.currentUser!.id;
      final tasks = _tasksController.text.trim();
      final skills = _skillsController.text.trim();

      await _supabase.from('student_reports').upsert({
        'student_id': studentId,
        'report_type': widget.reportType,
        'tasks_completed': tasks,
        'skills_acquired': skills,
      }, onConflict: 'student_id, report_type'); // Assuming composite unique key
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.reportType} Report saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.reportType} Progress Report'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveReport,
              icon: const Icon(Icons.send),
              label: const Text('Submit'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tasks Completed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tasksController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Describe all tasks and responsibilities you have completed...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Skills Acquired',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _skillsController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'List the new technical or soft skills you have learned...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
