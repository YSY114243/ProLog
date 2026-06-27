import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'pdf_service.dart';

class PdfFormDelegates {
  static Future<pw.Widget> buildAcademicHeader(String title) async {
    pw.Widget logoWidget;
    try {
      final svgData = await rootBundle.loadString('assets/images/iau_logo.svg');
      logoWidget = pw.SvgImage(svg: svgData, width: 80);
    } catch (_) {
      logoWidget = pw.SizedBox(width: 80, height: 80);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logoWidget,
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

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 12)),
        ),
      ],
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

  static pw.Widget _buildLikertTable(List<Map<String, String>> questions, Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Domain / Question', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('2', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('3', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('4', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          ],
        ),
        ...questions.map((q) {
          final int score = int.tryParse(data[q['key']]?.toString() ?? '0') ?? 0;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(q['label'] as String, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 1 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 1 ? pw.FontWeight.bold : pw.FontWeight.normal))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 2 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 2 ? pw.FontWeight.bold : pw.FontWeight.normal))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 3 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 3 ? pw.FontWeight.bold : pw.FontWeight.normal))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 4 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 4 ? pw.FontWeight.bold : pw.FontWeight.normal))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 5 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 5 ? pw.FontWeight.bold : pw.FontWeight.normal))),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildStForm01(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Student's Information", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('ID:', student.universityId),
            _buildTableRow('Assigned Company:', data['assigned_company']?.toString() ?? ''),
            _buildTableRow('Company Location:', data['company_location']?.toString() ?? ''),
          ],
        ),
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
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('ID:', student.universityId),
            _buildTableRow('Major:', student.major),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text("Information to be provided by the supervisor", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Company Name:', data['company_name']?.toString() ?? ''),
            _buildTableRow('Supervisor Name:', data['supervisor_name']?.toString() ?? ''),
            _buildTableRow('Supervisor Position:', data['supervisor_position']?.toString() ?? ''),
            _buildTableRow('Training Start Date:', data['start_date']?.toString() ?? ''),
            _buildTableRow('Mobile Phone:', data['supervisor_mobile']?.toString() ?? ''),
            _buildTableRow('E-mail:', data['supervisor_email']?.toString() ?? ''),
            _buildTableRow('Address:', data['address']?.toString() ?? ''),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStForm03(StudentInfo student, Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('ID Number:', student.universityId),
            _buildTableRow('Company Name:', student.company),
          ],
        ),
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
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('ID Number:', student.universityId),
            _buildTableRow('Company Name:', student.company),
          ],
        ),
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
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('ID Number:', student.universityId),
            if (formId == 'ST-FORM 06') _buildTableRow('Company Name:', student.company),
            if (formId == 'ST-FORM 05') _buildTableRow('Department:', student.major),
          ],
        ),
        pw.SizedBox(height: 24),
        _buildBox('Reason(s)', data['reason']?.toString() ?? ''),
      ],
    );
  }

  static pw.Widget _buildStForm07(StudentInfo student, Map<String, dynamic> data) {
    final questions = [
      {'label': 'I was assigned meaningful tasks', 'key': 'q0'},
      {'label': 'Assignments were relevant to coursework', 'key': 'q1'},
      {'label': 'Assignments were relevant to interests', 'key': 'q2'},
      {'label': 'Regular supervision and guidance', 'key': 'q3'},
      {'label': 'Staff were available for questions', 'key': 'q4'},
      {'label': 'Learned new knowledge & skills', 'key': 'q5'},
      {'label': 'Facilities & resources were useful', 'key': 'q6'},
      {'label': 'Company is open to innovative ideas', 'key': 'q7'},
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Name:', student.name),
            _buildTableRow('Company Name:', student.company),
          ],
        ),
        pw.SizedBox(height: 24),
        _buildLikertTable(questions, data),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Recommend company?', data['recommend']?.toString() ?? ''),
          ],
        ),
        pw.SizedBox(height: 8),
        _buildBox('Additional Comments', data['comments']?.toString() ?? ''),
      ],
    );
  }

  static pw.Widget _buildStForm08(StudentInfo student, Map<String, dynamic> data) {
    final evalQuestions = [
      {'label': 'Application clear', 'key': 'app_clear'},
      {'label': 'Application efficient', 'key': 'app_efficient'},
      {'label': 'Orientation helpful', 'key': 'orientation_helpful'},
      {'label': 'Training plan clear', 'key': 'training_plan_clear'},
      {'label': 'Related to specialty', 'key': 'training_specialty'},
      {'label': 'Manual clear', 'key': 'manual_clear'},
      {'label': 'Manual relevant', 'key': 'manual_relevant'},
      {'label': 'Follow up freq.', 'key': 'follow_up_freq'},
      {'label': 'Supervisor effective', 'key': 'supervisor_effective'},
      {'label': 'Assessment clear', 'key': 'assessment_clear'},
      {'label': 'Assessment fair', 'key': 'assessment_fair'},
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Section 1: General Information', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            _buildTableRow('Gender:', data['gender']?.toString() ?? ''),
            _buildTableRow('College:', data['college']?.toString() ?? ''),
            _buildTableRow('Department:', data['department']?.toString() ?? ''),
            _buildTableRow('Level:', data['level']?.toString() ?? ''),
            _buildTableRow('Type of Field Training:', data['training_type']?.toString() ?? ''),
            _buildTableRow('How was this provided:', data['provided_by']?.toString() ?? ''),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Section 2: Evaluation (1-5)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildLikertTable(evalQuestions, data),
        pw.SizedBox(height: 16),
        pw.Text('Section 3: Comments', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildBox('Best experience(s)', data['best_exp']?.toString() ?? ''),
        _buildBox('Suggestions for IAU', data['suggestions']?.toString() ?? ''),
      ],
    );
  }
}
