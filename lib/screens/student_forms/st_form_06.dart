import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm06Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm06Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm06Tab> createState() => _StForm06TabState();
}

class _StForm06TabState extends State<StForm06Tab> {
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
        const Text('Withdrawal Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(
          controller: _reasonCtrl,
          maxLines: 15,
          decoration: const InputDecoration(
            labelText: 'Reason(s) for the withdrawal',
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
