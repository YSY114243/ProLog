import 'package:flutter/material.dart';
import 'form_action_buttons.dart';

class StForm08Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm08Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm08Tab> createState() => _StForm08TabState();
}

class _StForm08TabState extends State<StForm08Tab> {
  // Section 1
  String _gender = '';
  final _collegeCtrl = TextEditingController();
  String _department = 'Computer Science';
  String _level = 'Senior';
  String _trainingType = '';
  String _providedBy = '';

  // Section 2
  double _appClear = 3;
  double _appEfficient = 3;
  
  String _orientationConducted = '';
  double _orientationHelpful = 3;
  double _trainingPlanClear = 3;
  double _trainingSpecialty = 3;

  String _manualProvided = '';
  double _manualClear = 3;
  double _manualRelevant = 3;

  String _supervisorAssigned = '';
  String _followUpFreq = '';
  double _supervisorEffective = 3;

  String _assessmentProvided = '';
  double _assessmentClear = 3;
  double _assessmentFair = 3;

  // Section 3
  final _bestExpCtrl = TextEditingController();
  final _suggestionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _gender = d['gender']?.toString() ?? '';
    _collegeCtrl.text = d['college']?.toString() ?? '';
    if (d['department'] != null && d['department'].toString().isNotEmpty) _department = d['department'];
    if (d['level'] != null && d['level'].toString().isNotEmpty) _level = d['level'];
    _trainingType = d['training_type']?.toString() ?? '';
    _providedBy = d['provided_by']?.toString() ?? '';

    _appClear = double.tryParse(d['app_clear']?.toString() ?? '3') ?? 3;
    _appEfficient = double.tryParse(d['app_efficient']?.toString() ?? '3') ?? 3;

    _orientationConducted = d['orientation_conducted']?.toString() ?? '';
    _orientationHelpful = double.tryParse(d['orientation_helpful']?.toString() ?? '3') ?? 3;
    _trainingPlanClear = double.tryParse(d['training_plan_clear']?.toString() ?? '3') ?? 3;
    _trainingSpecialty = double.tryParse(d['training_specialty']?.toString() ?? '3') ?? 3;

    _manualProvided = d['manual_provided']?.toString() ?? '';
    _manualClear = double.tryParse(d['manual_clear']?.toString() ?? '3') ?? 3;
    _manualRelevant = double.tryParse(d['manual_relevant']?.toString() ?? '3') ?? 3;

    _supervisorAssigned = d['supervisor_assigned']?.toString() ?? '';
    _followUpFreq = d['follow_up_freq']?.toString() ?? '';
    _supervisorEffective = double.tryParse(d['supervisor_effective']?.toString() ?? '3') ?? 3;

    _assessmentProvided = d['assessment_provided']?.toString() ?? '';
    _assessmentClear = double.tryParse(d['assessment_clear']?.toString() ?? '3') ?? 3;
    _assessmentFair = double.tryParse(d['assessment_fair']?.toString() ?? '3') ?? 3;

    _bestExpCtrl.text = d['best_exp']?.toString() ?? '';
    _suggestionsCtrl.text = d['suggestions']?.toString() ?? '';
  }

  @override
  void dispose() {
    _collegeCtrl.dispose();
    _bestExpCtrl.dispose();
    _suggestionsCtrl.dispose();
    super.dispose();
  }

  Widget _buildLikert(String title, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          value: value, min: 1, max: 5, divisions: 4,
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadio<T>(String title, List<T> options, T groupValue, Function(T?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Wrap(
          spacing: 16,
          children: options.map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<T>(value: opt, groupValue: groupValue, onChanged: onChanged),
                Text(opt.toString()),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Section 1: General Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildRadio<String>('Gender', ['Male', 'Female'], _gender, (val) => setState(() => _gender = val ?? '')),
        TextField(controller: _collegeCtrl, decoration: const InputDecoration(labelText: 'College', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _department,
          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
          items: ['Computer Science', 'Engineering', 'Business', 'Medicine', 'Other']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _department = val ?? ''),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _level,
          decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
          items: ['Freshman', 'Sophomore', 'Junior', 'Senior']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _level = val ?? ''),
        ),
        const SizedBox(height: 16),
        _buildRadio<String>('Type of Field Training', ['Clinical training', 'Internship', 'Summer training', 'COOP training'], _trainingType, (val) => setState(() => _trainingType = val ?? '')),
        _buildRadio<String>('How was this training opportunity provided', ['by college', 'by myself'], _providedBy, (val) => setState(() => _providedBy = val ?? '')),

        const Divider(height: 32),
        const Text('Section 2: Evaluation (1: Strongly disagree - 5: Strongly agree)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        
        const SizedBox(height: 16),
        const Text('Domain: Training Application', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        _buildLikert('The application process was clear', _appClear, (val) => setState(() => _appClear = val)),
        _buildLikert('The application process was efficient', _appEfficient, (val) => setState(() => _appEfficient = val)),

        const SizedBox(height: 16),
        const Text('Domain: Orientation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        _buildRadio<String>('An orientation was conducted by the College before training', ['Yes', 'No'], _orientationConducted, (val) => setState(() => _orientationConducted = val ?? '')),
        _buildLikert('The orientation was helpful', _orientationHelpful, (val) => setState(() => _orientationHelpful = val)),
        _buildLikert('The training plan was clear', _trainingPlanClear, (val) => setState(() => _trainingPlanClear = val)),
        _buildLikert('The training was related to the specialty', _trainingSpecialty, (val) => setState(() => _trainingSpecialty = val)),

        const SizedBox(height: 16),
        const Text('Domain: Training Program', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        _buildRadio<String>('A training manual was provided before training', ['Yes', 'No'], _manualProvided, (val) => setState(() => _manualProvided = val ?? '')),
        _buildLikert('The training manual was clear', _manualClear, (val) => setState(() => _manualClear = val)),
        _buildLikert('The training manual included relevant information needed', _manualRelevant, (val) => setState(() => _manualRelevant = val)),

        const SizedBox(height: 16),
        const Text('Domain: Training Supervision', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        _buildRadio<String>('The College assigned an Academic Supervisor for follow ups during training', ['Yes', 'No'], _supervisorAssigned, (val) => setState(() => _supervisorAssigned = val ?? '')),
        _buildRadio<String>('The Academic Supervisor performed routine follow ups with the trainee', ['Daily', 'Weekly', 'Bi-weekly', 'Monthly', 'Never'], _followUpFreq, (val) => setState(() => _followUpFreq = val ?? '')),
        _buildLikert('The Academic Supervisor dealt with issues faced by the trainee effectively', _supervisorEffective, (val) => setState(() => _supervisorEffective = val)),

        const SizedBox(height: 16),
        const Text('Domain: Assessment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        _buildRadio<String>('Assessment plan was provided', ['Yes', 'No'], _assessmentProvided, (val) => setState(() => _assessmentProvided = val ?? '')),
        _buildLikert('Assessment was clear', _assessmentClear, (val) => setState(() => _assessmentClear = val)),
        _buildLikert('Assessment was fair', _assessmentFair, (val) => setState(() => _assessmentFair = val)),

        const Divider(height: 32),
        const Text('Section 3: Brief written comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(controller: _bestExpCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'What was the best experience(s) of your field training?', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _suggestionsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'What suggestions would you give IAU to improve the training program?', border: OutlineInputBorder())),

        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: _saveAndDownload,
          onSubmit: _saveAndSubmit,
        ),
      ],
    );
  }

  Map<String, dynamic> _collectData() {
    return {
      'gender': _gender,
      'college': _collegeCtrl.text,
      'department': _department,
      'level': _level,
      'training_type': _trainingType,
      'provided_by': _providedBy,
      'app_clear': _appClear,
      'app_efficient': _appEfficient,
      'orientation_conducted': _orientationConducted,
      'orientation_helpful': _orientationHelpful,
      'training_plan_clear': _trainingPlanClear,
      'training_specialty': _trainingSpecialty,
      'manual_provided': _manualProvided,
      'manual_clear': _manualClear,
      'manual_relevant': _manualRelevant,
      'supervisor_assigned': _supervisorAssigned,
      'follow_up_freq': _followUpFreq,
      'supervisor_effective': _supervisorEffective,
      'assessment_provided': _assessmentProvided,
      'assessment_clear': _assessmentClear,
      'assessment_fair': _assessmentFair,
      'best_exp': _bestExpCtrl.text,
      'suggestions': _suggestionsCtrl.text,
    };
  }

  void _saveAndDownload() => widget.onDownload(_collectData());
  void _saveAndSubmit() => widget.onSubmit(_collectData());
}
