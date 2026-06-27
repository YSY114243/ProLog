import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm07Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm07Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm07Tab> createState() => _StForm07TabState();
}

class _StForm07TabState extends State<StForm07Tab> {
  final List<String> _questions = [
    'I was assigned meaningful tasks during my summer training',
    'My summer training assignments were relevant to my academic coursework',
    'My summer training assignments were relevant to my interests',
    'I had regular supervision and guidance from my supervisor',
    'My supervisor and/or other staff were available whenever I had questions',
    'I learned new knowledge & skills during my summer training',
    'The facilities & resources available at the company were useful to me during the training',
    'The training company is open to innovative ideas and the ideas generated are managed effectively',
  ];

  late List<double> _ratings;
  String _recommendCompany = '';
  final _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ratings = List.generate(
      _questions.length,
      (i) => double.tryParse(widget.initialData['q$i']?.toString() ?? '3') ?? 3,
    );
    _recommendCompany = widget.initialData['recommend']?.toString() ?? '';
    _commentsCtrl.text = widget.initialData['comments']?.toString() ?? '';
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Student's Evaluation of the Training Company", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        const Text("Please circle the appropriate number that indicates your rating level (1: Strongly Disagree - 5: Strongly Agree)", style: TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        for (int i = 0; i < _questions.length; i++) ...[
          Text('${i + 1}. ${_questions[i]}'),
          Slider(
            value: _ratings[i],
            min: 1,
            max: 5,
            divisions: 4,
            label: _ratings[i].toInt().toString(),
            onChanged: (val) => setState(() => _ratings[i] = val),
          ),
          const Divider(),
        ],
        const SizedBox(height: 16),
        const Text('Would you recommend this company for summer training to future students?', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 16,
          children: ['Yes', 'No', 'Undecided'].map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: opt,
                  groupValue: _recommendCompany,
                  onChanged: (val) => setState(() => _recommendCompany = val ?? ''),
                ),
                Text(opt),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Additional Comments (if any)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () {
            widget.onDownload({
              for (int i = 0; i < _questions.length; i++) 'q$i': _ratings[i],
              'recommend': _recommendCompany,
              'comments': _commentsCtrl.text,
            });
          },
          onSubmit: () {
            widget.onSubmit({
              for (int i = 0; i < _questions.length; i++) 'q$i': _ratings[i],
              'recommend': _recommendCompany,
              'comments': _commentsCtrl.text,
            });
          },
        ),
      ],
    );
  }
}
