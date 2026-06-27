import 'package:flutter/material.dart';

class FormActionButtons extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onSubmit;

  const FormActionButtons({super.key, required this.onDownload, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Preview / Download PDF'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.save),
          label: const Text('Save / Submit'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
