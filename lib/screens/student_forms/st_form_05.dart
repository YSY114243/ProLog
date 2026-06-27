import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm05Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm05Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm05Tab> createState() => _StForm05TabState();
}

class _StForm05TabState extends State<StForm05Tab> {
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reasonCtrl.text = widget.initialData['reason']?.toString() ?? '';
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Postponement Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(
          controller: _reasonCtrl,
          maxLines: 15,
          decoration: const InputDecoration(
            labelText: 'Reason(s) for the Postponement',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () => widget.onDownload({'reason': _reasonCtrl.text}),
          onSubmit: () => widget.onSubmit({'reason': _reasonCtrl.text}),
        ),
      ],
    );
  }
}
