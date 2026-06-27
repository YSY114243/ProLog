import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'pdf_service.dart';

class PdfFormDelegates {
  static Future<pw.Widget> buildAcademicHeader(String title) async {
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logoImage != null ? pw.Image(logoImage, width: 60, height: 60) : pw.SizedBox(width: 60, height: 60),
            pw.Text('College of Engineering\nImam Abdulrahman bin Faisal University', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget buildAcademicFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Student Signature: _______________________'),
            pw.Text('Supervisor Signature: _______________________'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Date: _______________________'),
          ],
        ),
      ],
    );
  }

  static Future<Uint8List> generateForm(StudentInfo student, String formId, Map<String, dynamic> data) async {
    final doc = pw.Document();
    pw.Font? formalFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/times.ttf');
      formalFont = pw.Font.ttf(fontData);
    } catch (_) {
      formalFont = pw.Font.times();
    }
    final theme = pw.ThemeData.withFont(base: formalFont, bold: pw.Font.timesBold(), italic: pw.Font.timesItalic(), boldItalic: pw.Font.timesBoldItalic());

    final header = await buildAcademicHeader('SUMMER TRAINING - $formId');

    pw.Widget content;
    switch (formId) {
      case 'ST-FORM 01':
        content = _buildStForm01(student, data);
        break;
      case 'ST-FORM 02':
        content = _buildStForm02(student, data);
        break;
      case 'ST-FORM 03':
        content = _buildStForm03(student, data);
        break;
      case 'ST-FORM 04':
        content = _buildStForm04(student, data);
        break;
      case 'ST-FORM 05':
      case 'ST-FORM 06':
        content = _buildStFormReason(student, data, formId);
        break;
      case 'ST-FORM 07':
        content = _buildStForm07(student, data);
        break;
      case 'ST-FORM 08':
        content = _buildStForm08(student, data);
        break;
      default:
        content = pw.Text('Form layout not defined for $formId');
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(theme: theme, pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(36)),
        header: (ctx) => header,
        footer: (ctx) => buildAcademicFooter(),
        build: (ctx) => [content],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static pw.Widget _buildBox(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
          child: pw.Text(content.isEmpty ? '—' : content, style: const pw.TextStyle(fontSize: 12)),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildStForm01(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Student's Information", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        _buildRow('Name:', student.name),
        _buildRow('ID:', student.universityId),
        _buildRow('Assigned Company:', data['assigned_company']?.toString() ?? ''),
        _buildRow('Company Location:', data['company_location']?.toString() ?? ''),
        pw.SizedBox(height: 24),
        pw.Text("Student's Undertaking", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Text(
          "By joining the Summer Training Program II, I the undersigned, agree to strictly abide by the obligations...",
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          data['agreed_to_obligations'] == true ? '[ X ] I agree to abide by the above obligations.' : '[   ] I agree to abide by the above obligations.',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildStForm02(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Student's Information", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        _buildRow('Name:', student.name),
        _buildRow('ID:', student.universityId),
        _buildRow('Major:', student.major),
        pw.SizedBox(height: 16),
        pw.Text("Information to be provided by the supervisor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        _buildRow('Company Name:', data['company_name']?.toString() ?? ''),
        _buildRow('Supervisor Name:', data['supervisor_name']?.toString() ?? ''),
        _buildRow('Supervisor Position:', data['supervisor_position']?.toString() ?? ''),
        _buildRow('Training Start Date:', data['start_date']?.toString() ?? ''),
        _buildRow('Mobile Phone:', data['supervisor_mobile']?.toString() ?? ''),
        _buildRow('E-mail:', data['supervisor_email']?.toString() ?? ''),
        _buildRow('Address:', data['address']?.toString() ?? ''),
      ],
    );
  }

  static pw.Widget _buildStForm03(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRow('Name:', student.name),
        _buildRow('ID Number:', student.universityId),
        _buildRow('Company Name:', student.company),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 1),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: ['Tasks Done', 'Problems Faced', 'Resources Used'],
          data: [
            [
              data['tasks_done']?.toString() ?? '',
              data['problems_faced']?.toString() ?? '',
              data['resources_used']?.toString() ?? ''
            ]
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStForm04(StudentInfo student, Map<String, dynamic> data) {
    List<List<String>> tableData = [];
    for (int i = 0; i < 8; i++) {
      final wData = data['week_${i + 1}'] as Map<String, dynamic>? ?? {};
      final date = wData['date']?.toString().split('T').first ?? '';
      final signature = wData['signature'] == true ? 'Signed' : '';
      final reason = wData['reason']?.toString() ?? '';
      tableData.add(['Week #${i + 1}', date, signature, reason]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRow('Name:', student.name),
        _buildRow('ID Number:', student.universityId),
        _buildRow('Company Name:', student.company),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 1),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: ['Week', 'Date', 'Signature', 'Reason'],
          data: tableData,
        ),
      ],
    );
  }

  static pw.Widget _buildStFormReason(StudentInfo student, Map<String, dynamic> data, String formId) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRow('Name:', student.name),
        _buildRow('ID Number:', student.universityId),
        if (formId == 'ST-FORM 06') _buildRow('Company Name:', student.company),
        if (formId == 'ST-FORM 05') _buildRow('Department:', student.major),
        pw.SizedBox(height: 24),
        _buildBox('Reason(s)', data['reason']?.toString() ?? ''),
      ],
    );
  }

  static pw.Widget _buildStForm07(StudentInfo student, Map<String, dynamic> data) {
    final questions = [
      'I was assigned meaningful tasks',
      'Assignments were relevant to coursework',
      'Assignments were relevant to interests',
      'Regular supervision and guidance',
      'Staff were available for questions',
      'Learned new knowledge & skills',
      'Facilities & resources were useful',
      'Company is open to innovative ideas',
    ];

    List<List<String>> tableData = [];
    for (int i = 0; i < questions.length; i++) {
      tableData.add([questions[i], data['q$i']?.toString() ?? '3']);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRow('Name:', student.name),
        _buildRow('Company Name:', student.company),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 1),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: ['Domain / Question', 'Rating (1-5)'],
          data: tableData,
        ),
        pw.SizedBox(height: 16),
        _buildRow('Recommend company?', data['recommend']?.toString() ?? ''),
        pw.SizedBox(height: 8),
        _buildBox('Additional Comments', data['comments']?.toString() ?? ''),
      ],
    );
  }

  static pw.Widget _buildStForm08(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Section 1: General Information', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildRow('Gender:', data['gender']?.toString() ?? ''),
        _buildRow('College:', data['college']?.toString() ?? ''),
        _buildRow('Department:', data['department']?.toString() ?? ''),
        _buildRow('Level:', data['level']?.toString() ?? ''),
        _buildRow('Type of Field Training:', data['training_type']?.toString() ?? ''),
        _buildRow('How was this provided:', data['provided_by']?.toString() ?? ''),
        pw.SizedBox(height: 16),
        pw.Text('Section 2: Evaluation (1-5)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(width: 1),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: ['Domain', 'Rating/Answer'],
          data: [
            ['Application clear', data['app_clear']?.toString() ?? ''],
            ['Application efficient', data['app_efficient']?.toString() ?? ''],
            ['Orientation conducted?', data['orientation_conducted']?.toString() ?? ''],
            ['Orientation helpful', data['orientation_helpful']?.toString() ?? ''],
            ['Training plan clear', data['training_plan_clear']?.toString() ?? ''],
            ['Related to specialty', data['training_specialty']?.toString() ?? ''],
            ['Manual provided?', data['manual_provided']?.toString() ?? ''],
            ['Manual clear', data['manual_clear']?.toString() ?? ''],
            ['Manual relevant', data['manual_relevant']?.toString() ?? ''],
            ['Supervisor assigned?', data['supervisor_assigned']?.toString() ?? ''],
            ['Follow up freq.', data['follow_up_freq']?.toString() ?? ''],
            ['Supervisor effective', data['supervisor_effective']?.toString() ?? ''],
            ['Assessment provided?', data['assessment_provided']?.toString() ?? ''],
            ['Assessment clear', data['assessment_clear']?.toString() ?? ''],
            ['Assessment fair', data['assessment_fair']?.toString() ?? ''],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Section 3: Comments', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildBox('Best experience(s)', data['best_exp']?.toString() ?? ''),
        _buildBox('Suggestions for IAU', data['suggestions']?.toString() ?? ''),
      ],
    );
  }
}
