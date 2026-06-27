import 'package:flutter/material.dart';

class FormFieldConfig {
  final String key;
  final String label;
  final bool isMultiline;

  FormFieldConfig({
    required this.key,
    required this.label,
    this.isMultiline = false,
  });
}

class DynamicFormBuilder extends StatefulWidget {
  final List<FormFieldConfig> fields;
  final Map<String, dynamic> initialData;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final Future<void> Function() onDownloadPdf;

  const DynamicFormBuilder({
    super.key,
    required this.fields,
    this.initialData = const {},
    required this.onSubmit,
    required this.onDownloadPdf,
  });

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _controllers[field.key] = TextEditingController(
        text: widget.initialData[field.key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    final data = <String, dynamic>{};
    for (var entry in _controllers.entries) {
      data[entry.key] = entry.value.text;
    }
    try {
      await widget.onSubmit(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save form: $e')),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ...widget.fields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextField(
              controller: _controllers[field.key],
              maxLines: field.isMultiline ? 5 : 1,
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
                alignLabelWithHint: field.isMultiline,
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onDownloadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Preview / Download PDF'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSubmit,
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Save / Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
