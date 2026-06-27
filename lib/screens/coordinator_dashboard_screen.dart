import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import '../models/student_info.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() => _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState extends State<CoordinatorDashboardScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await SupabaseService.instance.getAllStudents();
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) async {
    final studentId = student['id'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch the evaluation and supervisor info
    final evaluation = await SupabaseService.instance.getEvaluationForStudent(studentId);
    
    Map<String, dynamic>? supervisorInfo;
    if (student['supervisor_id'] != null) {
      supervisorInfo = await SupabaseService.instance.getSupervisorProfile(student['supervisor_id']);
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    final studentInfo = StudentInfo(
      name: student['full_name'] ?? 'Unknown',
      universityId: student['university_id'] ?? 'N/A', // Adjust based on your schema
      major: student['major'] ?? 'N/A',
      universityName: student['university'] ?? 'N/A',
      company: student['company'] ?? 'N/A',
      supervisor: supervisorInfo?['full_name'] ?? 'N/A',
      supervisorEmail: 'N/A', // Replace with supervisor email if available in your schema
    );

    final plansRes = await Supabase.instance.client
        .from('training_plans')
        .select()
        .eq('student_id', studentId);
    final List<Map<String, dynamic>> trainingPlans = List<Map<String, dynamic>>.from(plansRes);

    final reportsRes = await Supabase.instance.client
        .from('student_reports')
        .select()
        .eq('student_id', studentId);
    final List<Map<String, dynamic>> studentReports = List<Map<String, dynamic>>.from(reportsRes);

    final midtermReport = studentReports.where((r) => r['report_type'] == 'Midterm').firstOrNull;
    final finalReport = studentReports.where((r) => r['report_type'] == 'Final').firstOrNull;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                studentInfo.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${studentInfo.major} • ${studentInfo.universityName}'),
              const SizedBox(height: 24),
              const Text('Official Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () async {
                  final pdfBytes = await PdfService.instance.generateStForm02Pdf(
                    student: studentInfo,
                    trainingStartDate: DateTime.now(), // Adjust if you have a start date field
                  );
                  await Printing.sharePdf(bytes: pdfBytes, filename: 'ST-FORM_02_${studentInfo.name}.pdf');
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download ST-FORM 02 (Start Form)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: trainingPlans.isEmpty
                    ? null
                    : () async {
                        final pdfBytes = await PdfService.instance.generateTaForm01Pdf(
                          student: studentInfo,
                          plans: trainingPlans,
                        );
                        await Printing.sharePdf(bytes: pdfBytes, filename: 'TA-FORM_01_${studentInfo.name}.pdf');
                      },
                icon: const Icon(Icons.list_alt),
                label: Text(trainingPlans.isEmpty
                    ? 'TA-FORM 01 (No Training Plan)'
                    : 'Download TA-FORM 01 (Training Plan)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: evaluation == null
                    ? null
                    : () async {
                        final pdfBytes = await PdfService.instance.generateTaForm03Pdf(
                          student: studentInfo,
                          evaluation: evaluation,
                        );
                        await Printing.sharePdf(bytes: pdfBytes, filename: 'TA-FORM_03_${studentInfo.name}.pdf');
                      },
                icon: const Icon(Icons.assessment),
                label: Text(evaluation == null 
                  ? 'TA-FORM 03 (Not Evaluated Yet)' 
                  : 'Download TA-FORM 03 (Supervisor Evaluation)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: midtermReport == null
                    ? null
                    : () async {
                        final pdfBytes = await PdfService.instance.generateStudentReportPdf(
                          student: studentInfo,
                          reportType: 'Midterm',
                          reportData: midtermReport,
                        );
                        await Printing.sharePdf(bytes: pdfBytes, filename: 'ST-FORM_03_${studentInfo.name}.pdf');
                      },
                icon: const Icon(Icons.description),
                label: Text(midtermReport == null
                    ? 'ST-FORM 03 (No Midterm Report)'
                    : 'Download ST-FORM 03 (Midterm Report)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: finalReport == null
                    ? null
                    : () async {
                        final pdfBytes = await PdfService.instance.generateStudentReportPdf(
                          student: studentInfo,
                          reportType: 'Final',
                          reportData: finalReport,
                        );
                        await Printing.sharePdf(bytes: pdfBytes, filename: 'ST-FORM_07_08_${studentInfo.name}.pdf');
                      },
                icon: const Icon(Icons.description),
                label: Text(finalReport == null
                    ? 'ST-FORM 07/08 (No Final Report)'
                    : 'Download ST-FORM 07/08 (Final Report)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(student['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(student['major'] ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showStudentDetails(student),
                      ),
                    );
                  },
                ),
    );
  }
}
