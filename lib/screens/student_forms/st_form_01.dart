import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm01Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm01Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm01Tab> createState() => _StForm01TabState();
}

class _StForm01TabState extends State<StForm01Tab> {
  final _assignedCompanyCtrl = TextEditingController();
  final _companyLocationCtrl = TextEditingController();
  bool _agreedToObligations = false;

  @override
  void initState() {
    super.initState();
    _assignedCompanyCtrl.text = widget.initialData['assigned_company']?.toString() ?? '';
    _companyLocationCtrl.text = widget.initialData['company_location']?.toString() ?? '';
    _agreedToObligations = widget.initialData['agreed_to_obligations'] == true;
  }

  @override
  void dispose() {
    _assignedCompanyCtrl.dispose();
    _companyLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Student Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(
          controller: _assignedCompanyCtrl,
          decoration: const InputDecoration(labelText: 'Assigned Company', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyLocationCtrl,
          decoration: const InputDecoration(labelText: 'Company Location', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 32),
        const Text("Student's Undertaking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'By joining the Summer Training Program II, I the undersigned, agree to strictly abide by the following obligations:\n\n'
            '1. I must check after the end of this semester before leaving to my assigned training company that I am not among the dismissed or discontinued student.\n'
            '2. I must report to my assigned training company on the date assigned by the Summer Training Committee or otherwise as indicated above.\n'
            '3. I must spend a minimum of continuous eight (8) weeks in the above assigned company and shall not change the place unless with a prior permission of both the company and the Summer Training Committee.\n'
            '4. I must observe the laws and regulations of the training organization and shall not leave my place of training except with my supervisor\'s permission.\n'
            '5. I must send the Starting Date Form (FORM 03) to the Summer Training Committee/Training Coordinator within the first week of the start of my training.\n'
            '6. I must submit the duly stamped progress reports within the fourth and eight weeks of my training respectively.\n'
            '7. It is my responsibility to submit the stamped evaluation report form and booklet to the Training Coordinator during the first week of the semester preceding my training.\n'
            '8. I understand that any delay in submitting the progress reports and the evaluation report will affect my summer training grade.\n'
            '9. I will immediately communicate via e-mail/mobile to the Training Coordinator whenever I am facing any problem in trying to abide by the aforementioned rules and regulations.\n'
            '10. Once I decided to drop the training, I will immediately fill in the Drop Form and send it to the Training coordinator.',
            style: TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('I agree to abide by the above obligations.'),
          value: _agreedToObligations,
          onChanged: (val) => setState(() => _agreedToObligations = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () {
            widget.onDownload({
              'assigned_company': _assignedCompanyCtrl.text,
              'company_location': _companyLocationCtrl.text,
              'agreed_to_obligations': _agreedToObligations,
            });
          },
          onSubmit: () {
            widget.onSubmit({
              'assigned_company': _assignedCompanyCtrl.text,
              'company_location': _companyLocationCtrl.text,
              'agreed_to_obligations': _agreedToObligations,
            });
          },
        ),
      ],
    );
  }
}
