import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingPlanScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const TrainingPlanScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final _supabase = Supabase.instance.client;
  final List<TextEditingController> _controllers = List.generate(8, (_) => TextEditingController());
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPlan();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingPlan() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('training_plans')
          .select('week_number, planned_tasks')
          .eq('student_id', widget.studentId);
      
      for (var row in response) {
        final weekNum = row['week_number'] as int;
        if (weekNum >= 1 && weekNum <= 8) {
          _controllers[weekNum - 1].text = row['planned_tasks'] as String;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load training plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePlan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    try {
      final supervisorId = _supabase.auth.currentUser!.id;
      final List<Map<String, dynamic>> toUpsert = [];
      
      for (int i = 0; i < 8; i++) {
        final text = _controllers[i].text.trim();
        if (text.isNotEmpty) {
          toUpsert.add({
            'student_id': widget.studentId,
            'supervisor_id': supervisorId,
            'week_number': i + 1,
            'planned_tasks': text,
          });
        }
      }

      if (toUpsert.isNotEmpty) {
        await _supabase.from('training_plans').upsert(
          toUpsert, 
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training Plan saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving plan: $e')),
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
        title: Text('Training Plan: ${widget.studentName}'),
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
              onPressed: _savePlan,
              icon: const Icon(Icons.save),
              label: const Text('Save Plan'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              itemBuilder: (context, index) {
                final weekNum = index + 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week $weekNum',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[index],
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter planned tasks for this week...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
