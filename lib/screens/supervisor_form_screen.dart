import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import '../services/pdf_overlay_mapper.dart';

class SupervisorFormScreen extends StatefulWidget {
  final String studentId;

  const SupervisorFormScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<SupervisorFormScreen> createState() => _SupervisorFormScreenState();
}

class _SupervisorFormScreenState extends State<SupervisorFormScreen> {

  Future<void> _submitForm(String formType, Map<String, dynamic> data) async {
    try {
      await SupabaseService.instance.upsertFormData(widget.studentId, formType, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$formType saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save $formType: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List> _generatePdfForForm(String formId, Map<String, dynamic> data, StudentInfo student) async {
    if (formId == 'TA-FORM 01') {
      return PdfService.instance.generateTaForm01Pdf(student: student, formData: data);
    } else if (formId == 'TA-FORM 03') {
      return PdfService.instance.generateTaForm03Pdf(student: student, evaluation: data);
    } else if (formId == 'TA-FORM 04') {
      return PdfOverlayMapper.generateTaForm04(student: student, data: data);
    } else {
      return PdfService.instance.generateGenericFormPdf(
        student: student,
        formId: formId,
        formData: data,
      );
    }
  }

  Future<void> _handleDownloadPdf(String formId, Map<String, dynamic> data) async {
    final profile = await SupabaseService.instance.getUserProfile();
    final student = StudentInfo(
      name: 'Trainee',
      universityId: '2190000000',
      major: 'Civil Engineering',
      universityName: 'Imam Abdulrahman bin Faisal University',
      company: 'Company',
      supervisor: profile?['full_name'] ?? 'Supervisor',
    );
    
    final pdfBytes = await _generatePdfForForm(formId, data, student);
    await Printing.sharePdf(bytes: pdfBytes, filename: '${formId.replaceAll(' ', '_')}.pdf');
  }

  Future<void> _handleEmailToCoordinator(String formId, Map<String, dynamic> data) async {
    final profile = await SupabaseService.instance.getUserProfile();
    final student = StudentInfo(
      name: 'Trainee',
      universityId: '2190000000',
      major: 'Civil Engineering',
      universityName: 'Imam Abdulrahman bin Faisal University',
      company: 'Company',
      supervisor: profile?['full_name'] ?? 'Supervisor',
    );
    
    try {
      final pdfBytes = await _generatePdfForForm(formId, data, student);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${formId.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Confidential Training Document - $formId',
        text: 'Dear Academic Coordinator,\n\nPlease find attached the completed training document.\n\nSent via InternLog App.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervisor Forms'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Training Plan'),
              Tab(text: 'Evaluation'),
              Tab(text: 'Agency Survey'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FormTabWrapper(
              studentId: widget.studentId,
              formId: 'TA-FORM 01',
              builder: (data) => _TaForm01Tab(
                initialData: data,
                onSubmit: (d) => _submitForm('TA-FORM 01', d),
                onDownload: (d) => _handleDownloadPdf('TA-FORM 01', d),
                onEmail: (d) => _handleEmailToCoordinator('TA-FORM 01', d),
              ),
            ),
            FormTabWrapper(
              studentId: widget.studentId,
              formId: 'TA-FORM 03',
              builder: (data) => _TaForm03Tab(
                initialData: data,
                onSubmit: (d) => _submitForm('TA-FORM 03', d),
                onDownload: (d) => _handleDownloadPdf('TA-FORM 03', d),
                onEmail: (d) => _handleEmailToCoordinator('TA-FORM 03', d),
              ),
            ),
            FormTabWrapper(
              studentId: widget.studentId,
              formId: 'TA-FORM 04',
              builder: (data) => _TaForm04Tab(
                initialData: data,
                onSubmit: (d) => _submitForm('TA-FORM 04', d),
                onDownload: (d) => _handleDownloadPdf('TA-FORM 04', d),
                onEmail: (d) => _handleEmailToCoordinator('TA-FORM 04', d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormTabWrapper extends StatelessWidget {
  final String formId;
  final String studentId;
  final Widget Function(Map<String, dynamic> data) builder;

  const FormTabWrapper({
    super.key, 
    required this.formId, 
    required this.studentId, 
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.instance.fetchFormData(studentId, formId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(snapshot.data ?? {});
      },
    );
  }
}

class _TaForm01Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;
  final Function(Map<String, dynamic>) onEmail;

  const _TaForm01Tab({required this.initialData, required this.onSubmit, required this.onDownload, required this.onEmail});

  @override
  State<_TaForm01Tab> createState() => _TaForm01TabState();
}

class _TaForm01TabState extends State<_TaForm01Tab> {
  final List<TextEditingController> _ctrls = List.generate(8, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 8; i++) {
      _ctrls[i].text = widget.initialData['week_${i + 1}']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (var ctrl in _ctrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (int i = 0; i < 8; i++) ...[
          TextField(
            controller: _ctrls[i],
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Expected Training Activities - Week ${i + 1}',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        _ActionButtons(
          onDownload: () {
            final data = {for (int i = 0; i < 8; i++) 'week_${i + 1}': _ctrls[i].text};
            widget.onDownload(data);
          },
          onEmail: () {
            final data = {for (int i = 0; i < 8; i++) 'week_${i + 1}': _ctrls[i].text};
            widget.onEmail(data);
          },
          onSubmit: () {
            final data = {for (int i = 0; i < 8; i++) 'week_${i + 1}': _ctrls[i].text};
            widget.onSubmit(data);
          },
        ),
      ],
    );
  }
}

class _TaForm03Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;
  final Function(Map<String, dynamic>) onEmail;

  const _TaForm03Tab({required this.initialData, required this.onSubmit, required this.onDownload, required this.onEmail});

  @override
  State<_TaForm03Tab> createState() => _TaForm03TabState();
}

class _TaForm03TabState extends State<_TaForm03Tab> {
  final List<String> _criteria = [
    'Enthusiasm and interest in work.',
    'Attitude towards delivering accurate work.',
    'Ability in understanding and dealing with new system.',
    'Initiative in taking tasks to completion.',
    'Dependability and reliability.',
    'Ability to learn and search for information.',
    'Judgment and decision making.',
    'Maintaining effective relations with his/her work colleagues.',
    'Ability of reporting and presenting his/her work.',
    'Attendance and punctuality.'
  ];
  final Map<String, int> _ratings = {};
  final TextEditingController _commentsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var c in _criteria) {
      _ratings[c] = (widget.initialData[c] as num?)?.toInt() ?? 3;
    }
    _commentsCtrl.text = widget.initialData['additional_comments']?.toString() ?? '';
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
        const Text('Rate on a scale of 1 (Poor) to 5 (Excellent)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        for (var c in _criteria) ...[
          Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _ratings[c]!.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _ratings[c].toString(),
            onChanged: (val) => setState(() => _ratings[c] = val.toInt()),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _commentsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Additional Comments',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 32),
        _ActionButtons(
          onDownload: () {
            final data = {..._ratings, 'additional_comments': _commentsCtrl.text};
            widget.onDownload(data);
          },
          onEmail: () {
            final data = {..._ratings, 'additional_comments': _commentsCtrl.text};
            widget.onEmail(data);
          },
          onSubmit: () {
            final data = {..._ratings, 'additional_comments': _commentsCtrl.text};
            widget.onSubmit(data);
          },
        ),
      ],
    );
  }
}

class _TaForm04Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;
  final Function(Map<String, dynamic>) onEmail;

  const _TaForm04Tab({required this.initialData, required this.onSubmit, required this.onDownload, required this.onEmail});

  @override
  State<_TaForm04Tab> createState() => _TaForm04TabState();
}

class _TaForm04TabState extends State<_TaForm04Tab> {
  final TextEditingController _genderCtrl = TextEditingController();
  final TextEditingController _agencyCtrl = TextEditingController();
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _trainedPast2YearsCtrl = TextEditingController();
  final TextEditingController _currentlyTrainingCtrl = TextEditingController();

  final List<String> _likertQuestions = [
    'Application process was clear',
    'Application process was efficient',
    'Issues encountered relating to the trainee were resolved effectively',
    'The training manual was clear',
    'The training manual included relevant information needed for guiding the trainees',
    'Trainee Assessment and Evaluation forms were clear',
    'IAU students were ready for training',
    'IAU students demonstrated professionalism while undertaking training',
  ];

  String _communicationFreq = 'Weekly';
  String _providedManual = 'Yes';
  String _providedForms = 'Yes';

  final Map<String, int> _ratings = {};

  final TextEditingController _bestQualityCtrl = TextEditingController();
  final TextEditingController _suggestionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _genderCtrl.text = widget.initialData['students_gender']?.toString() ?? '';
    _agencyCtrl.text = widget.initialData['training_agency']?.toString() ?? '';
    _deptCtrl.text = widget.initialData['department']?.toString() ?? '';
    _trainedPast2YearsCtrl.text = widget.initialData['trained_past_2_years']?.toString() ?? '';
    _currentlyTrainingCtrl.text = widget.initialData['currently_training']?.toString() ?? '';

    _communicationFreq = widget.initialData['communication_freq']?.toString() ?? 'Weekly';
    _providedManual = widget.initialData['provided_manual']?.toString() ?? 'Yes';
    _providedForms = widget.initialData['provided_forms']?.toString() ?? 'Yes';

    for (var q in _likertQuestions) {
      _ratings[q] = (widget.initialData[q] as num?)?.toInt() ?? 3;
    }
    
    _bestQualityCtrl.text = widget.initialData['best_quality']?.toString() ?? '';
    _suggestionsCtrl.text = widget.initialData['suggestions']?.toString() ?? '';
  }

  @override
  void dispose() {
    _genderCtrl.dispose();
    _agencyCtrl.dispose();
    _deptCtrl.dispose();
    _trainedPast2YearsCtrl.dispose();
    _currentlyTrainingCtrl.dispose();
    _bestQualityCtrl.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  Widget _buildSegmentedControl(String question, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3')),
              ButtonSegment<int>(value: 4, label: Text('4')),
              ButtonSegment<int>(value: 5, label: Text('5')),
            ],
            selected: {value},
            onSelectionChanged: (Set<int> newSelection) {
              onChanged(newSelection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String question, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildCard('Section 1: General Information', [
          TextField(controller: _genderCtrl, decoration: const InputDecoration(labelText: 'Students Gender (Male/Female)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _agencyCtrl, decoration: const InputDecoration(labelText: 'Training Agency', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _trainedPast2YearsCtrl, decoration: const InputDecoration(labelText: 'Students trained over past 2 years (IAU)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          TextField(controller: _currentlyTrainingCtrl, decoration: const InputDecoration(labelText: 'Students currently training (IAU)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        ]),

        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text('Section 2: Likert Scale Survey (1: Strongly Disagree - 5: Strongly Agree)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),

        _buildCard('Domain 1: Training Application', [
          _buildSegmentedControl('Application process was clear', _ratings['Application process was clear']!, (val) => setState(() => _ratings['Application process was clear'] = val)),
          _buildSegmentedControl('Application process was efficient', _ratings['Application process was efficient']!, (val) => setState(() => _ratings['Application process was efficient'] = val)),
        ]),

        _buildCard('Domain 2: Communication with College', [
          _buildDropdown('Communication frequency with college:', _communicationFreq, ['Daily', 'Weekly', 'Bi-weekly', 'Monthly', 'Never'], (val) => setState(() => _communicationFreq = val!)),
          _buildSegmentedControl('Issues encountered relating to the trainee were resolved effectively', _ratings['Issues encountered relating to the trainee were resolved effectively']!, (val) => setState(() => _ratings['Issues encountered relating to the trainee were resolved effectively'] = val)),
        ]),

        _buildCard('Domain 3: Training Program', [
          _buildDropdown('Provided with a training manual?', _providedManual, ['Yes', 'No'], (val) => setState(() => _providedManual = val!)),
          _buildSegmentedControl('The training manual was clear', _ratings['The training manual was clear']!, (val) => setState(() => _ratings['The training manual was clear'] = val)),
          _buildSegmentedControl('The training manual included relevant information needed for guiding the trainees', _ratings['The training manual included relevant information needed for guiding the trainees']!, (val) => setState(() => _ratings['The training manual included relevant information needed for guiding the trainees'] = val)),
        ]),

        _buildCard('Domain 4: Assessment', [
          _buildDropdown('Assessment forms provided by college?', _providedForms, ['Yes', 'No'], (val) => setState(() => _providedForms = val!)),
          _buildSegmentedControl('Trainee Assessment and Evaluation forms were clear', _ratings['Trainee Assessment and Evaluation forms were clear']!, (val) => setState(() => _ratings['Trainee Assessment and Evaluation forms were clear'] = val)),
        ]),

        _buildCard('Domain 5: Student Evaluation', [
          _buildSegmentedControl('IAU students were ready for training', _ratings['IAU students were ready for training']!, (val) => setState(() => _ratings['IAU students were ready for training'] = val)),
          _buildSegmentedControl('IAU students demonstrated professionalism while undertaking training', _ratings['IAU students demonstrated professionalism while undertaking training']!, (val) => setState(() => _ratings['IAU students demonstrated professionalism while undertaking training'] = val)),
        ]),

        _buildCard('Section 3: Brief written comments', [
          TextField(controller: _bestQualityCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Best quality observed in IAU trainees?', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _suggestionsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Suggestions to improve the training program?', border: OutlineInputBorder())),
        ]),

        const SizedBox(height: 16),
        _ActionButtons(
          onDownload: () {
            final data = {
              'students_gender': _genderCtrl.text,
              'training_agency': _agencyCtrl.text,
              'department': _deptCtrl.text,
              'trained_past_2_years': _trainedPast2YearsCtrl.text,
              'currently_training': _currentlyTrainingCtrl.text,
              'communication_freq': _communicationFreq,
              'provided_manual': _providedManual,
              'provided_forms': _providedForms,
              'best_quality': _bestQualityCtrl.text,
              'suggestions': _suggestionsCtrl.text,
              ..._ratings,
            };
            widget.onDownload(data);
          },
          onEmail: () {
            final data = {
              'students_gender': _genderCtrl.text,
              'training_agency': _agencyCtrl.text,
              'department': _deptCtrl.text,
              'trained_past_2_years': _trainedPast2YearsCtrl.text,
              'currently_training': _currentlyTrainingCtrl.text,
              'communication_freq': _communicationFreq,
              'provided_manual': _providedManual,
              'provided_forms': _providedForms,
              'best_quality': _bestQualityCtrl.text,
              'suggestions': _suggestionsCtrl.text,
              ..._ratings,
            };
            widget.onEmail(data);
          },
          onSubmit: () {
            final data = {
              'students_gender': _genderCtrl.text,
              'training_agency': _agencyCtrl.text,
              'department': _deptCtrl.text,
              'trained_past_2_years': _trainedPast2YearsCtrl.text,
              'currently_training': _currentlyTrainingCtrl.text,
              'communication_freq': _communicationFreq,
              'provided_manual': _providedManual,
              'provided_forms': _providedForms,
              'best_quality': _bestQualityCtrl.text,
              'suggestions': _suggestionsCtrl.text,
              ..._ratings,
            };
            widget.onSubmit(data);
          },
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onEmail;
  final VoidCallback onSubmit;

  const _ActionButtons({required this.onDownload, required this.onEmail, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: onEmail,
              icon: const Icon(Icons.email),
              label: const Text('Generate & Email to Coordinator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
