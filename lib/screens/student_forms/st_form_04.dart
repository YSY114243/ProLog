import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'form_action_buttons.dart';

class StForm04Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm04Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm04Tab> createState() => _StForm04TabState();
}

class _StForm04TabState extends State<StForm04Tab> {
  final List<TextEditingController> _reasonCtrls = List.generate(8, (_) => TextEditingController());
  final List<DateTime?> _dates = List.generate(8, (_) => null);
  final List<bool> _signatures = List.generate(8, (_) => false);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 8; i++) {
      final wData = widget.initialData['week_${i + 1}'] as Map<String, dynamic>? ?? {};
      _reasonCtrls[i].text = wData['reason']?.toString() ?? '';
      _signatures[i] = wData['signature'] == true;
      if (wData['date'] != null) {
        _dates[i] = DateTime.tryParse(wData['date'].toString());
      }
    }
  }

  @override
  void dispose() {
    for (var ctrl in _reasonCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dates[index] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _dates[index] = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Attendance Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(3),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                Padding(padding: EdgeInsets.all(8.0), child: Text('Week', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Signature', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Reason (if absent)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            for (int i = 0; i < 8; i++)
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: Center(child: Text('Week #${i + 1}'))),
                  InkWell(
                    onTap: () => _pickDate(i),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(_dates[i] != null ? DateFormat('yyyy-MM-dd').format(_dates[i]!) : 'Select Date', style: const TextStyle(color: Colors.blue)),
                    ),
                  ),
                  Checkbox(
                    value: _signatures[i],
                    onChanged: (val) => setState(() => _signatures[i] = val ?? false),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: _reasonCtrls[i],
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () {
            widget.onDownload({
              for (int i = 0; i < 8; i++)
                'week_${i + 1}': {
                  'date': _dates[i]?.toIso8601String(),
                  'signature': _signatures[i],
                  'reason': _reasonCtrls[i].text,
                }
            });
          },
          onSubmit: () {
            widget.onSubmit({
              for (int i = 0; i < 8; i++)
                'week_${i + 1}': {
                  'date': _dates[i]?.toIso8601String(),
                  'signature': _signatures[i],
                  'reason': _reasonCtrls[i].text,
                }
            });
          },
        ),
      ],
    );
  }
}
