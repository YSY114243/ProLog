import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'form_action_buttons.dart';

class StForm02Tab extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(Map<String, dynamic>) onDownload;

  const StForm02Tab({super.key, required this.initialData, required this.onSubmit, required this.onDownload});

  @override
  State<StForm02Tab> createState() => _StForm02TabState();
}

class _StForm02TabState extends State<StForm02Tab> {
  final _companyNameCtrl = TextEditingController();
  final _supervisorNameCtrl = TextEditingController();
  final _supervisorPosCtrl = TextEditingController();
  final _supervisorMobileCtrl = TextEditingController();
  final _supervisorEmailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl.text = widget.initialData['company_name']?.toString() ?? '';
    _supervisorNameCtrl.text = widget.initialData['supervisor_name']?.toString() ?? '';
    _supervisorPosCtrl.text = widget.initialData['supervisor_position']?.toString() ?? '';
    _supervisorMobileCtrl.text = widget.initialData['supervisor_mobile']?.toString() ?? '';
    _supervisorEmailCtrl.text = widget.initialData['supervisor_email']?.toString() ?? '';
    _addressCtrl.text = widget.initialData['address']?.toString() ?? '';

    if (widget.initialData['start_date'] != null) {
      _startDate = DateTime.tryParse(widget.initialData['start_date'].toString());
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _supervisorPosCtrl.dispose();
    _supervisorMobileCtrl.dispose();
    _supervisorEmailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Information to be provided by the supervisor at the training company', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        TextField(controller: _companyNameCtrl, decoration: const InputDecoration(labelText: 'Company\'s Name', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _supervisorNameCtrl, decoration: const InputDecoration(labelText: 'Supervisor\'s Name', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _supervisorPosCtrl, decoration: const InputDecoration(labelText: 'Supervisor\'s Position', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Training Start Date',
              border: OutlineInputBorder(),
            ),
            child: Text(_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Select Date'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(controller: _supervisorMobileCtrl, decoration: const InputDecoration(labelText: 'Supervisor\'s Mobile Phone No', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        TextField(controller: _supervisorEmailCtrl, decoration: const InputDecoration(labelText: 'Supervisor\'s E-mail', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        TextField(controller: _addressCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
        const SizedBox(height: 32),
        FormActionButtons(
          onDownload: () {
            widget.onDownload({
              'company_name': _companyNameCtrl.text,
              'supervisor_name': _supervisorNameCtrl.text,
              'supervisor_position': _supervisorPosCtrl.text,
              'start_date': _startDate?.toIso8601String(),
              'supervisor_mobile': _supervisorMobileCtrl.text,
              'supervisor_email': _supervisorEmailCtrl.text,
              'address': _addressCtrl.text,
            });
          },
          onSubmit: () {
            widget.onSubmit({
              'company_name': _companyNameCtrl.text,
              'supervisor_name': _supervisorNameCtrl.text,
              'supervisor_position': _supervisorPosCtrl.text,
              'start_date': _startDate?.toIso8601String(),
              'supervisor_mobile': _supervisorMobileCtrl.text,
              'supervisor_email': _supervisorEmailCtrl.text,
              'address': _addressCtrl.text,
            });
          },
        ),
      ],
    );
  }
}
