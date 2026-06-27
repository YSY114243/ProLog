import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm03Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm03Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm03Tab> createState() => _StForm03TabState();
}

class _StForm03TabState extends State<StForm03Tab> {
  final _tasksCtrl = TextEditingController();
  final _problemsCtrl = TextEditingController();
  final _resourcesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tasksCtrl.text = widget.initialData['tasks_done']?.toString() ?? '';
    _problemsCtrl.text = widget.initialData['problems_faced']?.toString() ?? '';
    _resourcesCtrl.text = widget.initialData['resources_used']?.toString() ?? '';
  }

  @override
  void dispose() {
    _tasksCtrl.dispose();
    _problemsCtrl.dispose();
    _resourcesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Progress Report Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Brief description of activities, assignments, projects and type of training you were involved biweekly and the problems faced with the resources used (Individuals, Books, and websites).', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          controller: _tasksCtrl,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Tasks Done', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _problemsCtrl,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Problems Faced', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _resourcesCtrl,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Resources Used', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () {
            widget.onDownload({
              'tasks_done': _tasksCtrl.text,
              'problems_faced': _problemsCtrl.text,
              'resources_used': _resourcesCtrl.text,
            });
          },
          onSubmit: () {
            widget.onSubmit({
              'tasks_done': _tasksCtrl.text,
              'problems_faced': _problemsCtrl.text,
              'resources_used': _resourcesCtrl.text,
            });
          },
        ),
      ],
    );
  }
}
