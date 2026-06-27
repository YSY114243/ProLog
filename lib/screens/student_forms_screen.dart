import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';

import 'student_forms/st_form_01.dart';
import 'student_forms/st_form_02.dart';
import 'student_forms/st_form_03.dart';
import 'student_forms/st_form_04.dart';
import 'student_forms/st_form_05.dart';
import 'student_forms/st_form_06.dart';
import 'student_forms/st_form_07.dart';
import 'student_forms/st_form_08.dart';

class StudentFormsScreen extends StatefulWidget {
  const StudentFormsScreen({super.key});

  @override
  State<StudentFormsScreen> createState() => _StudentFormsScreenState();
}

class _StudentFormsScreenState extends State<StudentFormsScreen> {
  final List<String> _formIds = [
    'ST-FORM 01', 'ST-FORM 02', 'ST-FORM 03', 'ST-FORM 04',
    'ST-FORM 05', 'ST-FORM 06', 'ST-FORM 07', 'ST-FORM 08'
  ];

  Future<Map<String, dynamic>> _fetchData(String formId) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return {};
    final data = await SupabaseService.instance.fetchFormData(userId, formId);
    return data ?? {};
  }

  Future<void> _handleDownloadPdf(String formId, Map<String, dynamic> data) async {
    final profile = await SupabaseService.instance.getUserProfile();
    final student = StudentInfo(
      name: profile?['full_name'] ?? 'Unknown',
      universityId: '2190000000', // Hardcoded fallback for now
      major: profile?['major'] ?? 'Civil Engineering',
      universityName: profile?['uni_name'] ?? 'Imam Abdulrahman bin Faisal University',
      company: 'Company',
      supervisor: 'Unknown Supervisor',
    );
    
    final pdfBytes = await PdfService.instance.generateGenericFormPdf(
      student: student,
      formId: formId,
      formData: data,
    );
    
    await Printing.sharePdf(bytes: pdfBytes, filename: '$formId.pdf');
  }

  Future<void> _handleSubmit(String formId, Map<String, dynamic> data) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId != null) {
      await SupabaseService.instance.upsertFormData(userId, formId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$formId saved successfully!')),
        );
      }
    }
  }

  Widget _buildFormTab(String formId, Map<String, dynamic> initialData) {
    switch (formId) {
      case 'ST-FORM 01':
        return StForm01Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 02':
        return StForm02Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 03':
        return StForm03Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 04':
        return StForm04Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 05':
        return StForm05Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 06':
        return StForm06Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 07':
        return StForm07Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      case 'ST-FORM 08':
        return StForm08Tab(
          initialData: initialData,
          onSubmit: (data) => _handleSubmit(formId, data),
          onDownload: (data) => _handleDownloadPdf(formId, data),
        );
      default:
        return Center(child: Text('Unknown form: $formId'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _formIds.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Forms'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _formIds.map((id) => Tab(text: id)).toList(),
          ),
        ),
        body: TabBarView(
          children: _formIds.map((formId) {
            return FutureBuilder<Map<String, dynamic>>(
              // Using a stable future key based on formId to prevent re-fetching on small state changes,
              // but since we aren't caching the future, we rely on the TabBarView to preserve state.
              future: _fetchData(formId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final initialData = snapshot.data ?? {};
                return _buildFormTab(formId, initialData);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
