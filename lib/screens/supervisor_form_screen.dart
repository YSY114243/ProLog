import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';

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
    
    final pdfBytes = await PdfService.instance.generateGenericFormPdf(
      student: student,
      formId: formId,
      formData: data,
    );
    
    await Printing.sharePdf(bytes: pdfBytes, filename: '$formId.pdf');
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
              ),
            ),
            FormTabWrapper(
              studentId: widget.studentId,
              formId: 'TA-FORM 03',
              builder: (data) => _TaForm03Tab(
                initialData: data,
                onSubmit: (d) => _submitForm('TA-FORM 03', d),
                onDownload: (d) => _handleDownloadPdf('TA-FORM 03', d),
              ),
            ),
            FormTabWrapper(
              studentId: widget.studentId,
              formId: 'TA-FORM 04',
              builder: (data) => _TaForm04Tab(
                initialData: data,
                onSubmit: (d) => _submitForm('TA-FORM 04', d),
                onDownload: (d) => _handleDownloadPdf('TA-FORM 04', d),
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

  const _TaForm01Tab({required this.initialData, required this.onSubmit, required this.onDownload});

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

  const _TaForm03Tab({required this.initialData, required this.onSubmit, required this.onDownload});

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

  const _TaForm04Tab({required this.initialData, required this.onSubmit, required this.onDownload});

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Section 1: General Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(controller: _genderCtrl, decoration: const InputDecoration(labelText: 'Students Gender (Male/Female)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _agencyCtrl, decoration: const InputDecoration(labelText: 'Training Agency', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _trainedPast2YearsCtrl, decoration: const InputDecoration(labelText: 'Students trained over past 2 years (IAU)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: _currentlyTrainingCtrl, decoration: const InputDecoration(labelText: 'Students currently training (IAU)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        
        const SizedBox(height: 32),
        const Text('Section 2: Likert Scale Survey (1: Strongly Disagree - 5: Strongly Agree)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        
        for (var q in _likertQuestions) ...[
          Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _ratings[q]!.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _ratings[q].toString(),
            onChanged: (val) => setState(() => _ratings[q] = val.toInt()),
          ),
          const SizedBox(height: 16),
        ],

        const Text('Communication frequency with college:', style: TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          value: _communicationFreq,
          isExpanded: true,
          items: ['Daily', 'Weekly', 'Bi-weekly', 'Monthly', 'Never']
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) => setState(() => _communicationFreq = val!),
        ),
        const SizedBox(height: 16),

        const Text('Provided with a training manual?', style: TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          value: _providedManual,
          isExpanded: true,
          items: ['Yes', 'No'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => _providedManual = val!),
        ),
        const SizedBox(height: 16),

        const Text('Assessment forms provided by college?', style: TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          value: _providedForms,
          isExpanded: true,
          items: ['Yes', 'No'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => _providedForms = val!),
        ),

        const SizedBox(height: 32),
        const Text('Section 3: Brief written comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(controller: _bestQualityCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Best quality observed in IAU trainees?', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _suggestionsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Suggestions to improve the training program?', border: OutlineInputBorder())),
        
        const SizedBox(height: 32),
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
  final VoidCallback onSubmit;

  const _ActionButtons({required this.onDownload, required this.onSubmit});

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
