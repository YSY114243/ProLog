import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_overlay_service.dart';
import 'pdf_service.dart';

class PdfOverlayMapper {
  /// Generates the ST-FORM 01 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateStForm01({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_01_p1.png',
      fields: [],
    );

    final page2 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_01_p2.png',
      fields: [
        OverlayField.text(student.name, x: 156, y: 193),
        OverlayField.text(student.universityId, x: 466, y: 193),
        OverlayField.text(data['department']?.toString() ?? student.major, x: 156, y: 223),
        OverlayField.text(data['training_start_date']?.toString() ?? '', x: 466, y: 223),
        OverlayField.text(data['assigned_company']?.toString() ?? '', x: 156, y: 255),
        OverlayField.text(data['company_location']?.toString() ?? '', x: 466, y: 255),

        // Signatures
        OverlayField.text('Signed by: ${student.name}', x: 186, y: 740, fontSize: 10),
        OverlayField.text(dateFormat.format(DateTime.now()), x: 440, y: 740, fontSize: 10),
      ].whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1, page2]);
  }

  /// Generates the ST-FORM 02 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateStForm02({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_02_p1.png',
      fields: [
        // Student Info
        OverlayField.text(student.name, x: 270, y: 187),
        OverlayField.text(student.universityId, x: 270, y: 208),
        OverlayField.text(data['major']?.toString() ?? student.major, x: 270, y: 234),
        OverlayField.text(data['student_mobile']?.toString() ?? '', x: 270, y: 254),
        OverlayField.text(data['student_email']?.toString() ?? '', x: 270, y: 280),
        
        // Company & Supervisor Info
        OverlayField.text(data['company_name']?.toString() ?? '', x: 260, y: 340),
        OverlayField.text(data['supervisor_name']?.toString() ?? '', x: 260, y: 373),
        OverlayField.text(data['supervisor_position']?.toString() ?? '', x: 260, y: 400),
        OverlayField.text(data['training_start_date']?.toString() ?? '', x: 260, y: 427),
        OverlayField.text(data['supervisor_mobile']?.toString() ?? '', x: 260, y: 452),
        OverlayField.text(data['supervisor_email']?.toString() ?? '', x: 260, y: 478),
        OverlayField.text(data['address']?.toString() ?? '', x: 260, y: 515),

        // Signatures & Dates
        OverlayField.text('Digital Stamp: ${data['supervisor_name'] ?? student.supervisor}', x: 180, y: 600, fontSize: 10),
        OverlayField.text(dateFormat.format(DateTime.now()), x: 180, y: 644, fontSize: 10),
        
        OverlayField.text('Digital Stamp: ${student.name}', x: 460, y: 600, fontSize: 10),
        OverlayField.text(dateFormat.format(DateTime.now()), x: 460, y: 644, fontSize: 10),

        // Company Stamp
        OverlayField.text('System Verified - InternLog', x: 180, y: 695, fontSize: 10, color: const PdfColor(0.5, 0.5, 0.5)),
      ].whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1]);
  }

  /// Generates the ST-FORM 03 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateStForm03({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_03_p1.png',
      fields: [
        // Single-line Info
        OverlayField.text(student.name, x: 140, y: 250),
        OverlayField.text(student.universityId, x: 485, y: 250),
        OverlayField.text(data['company_name']?.toString() ?? '', x: 140, y: 294),
        
        // Multi-line Paragraphs
        OverlayField.text(data['tasks_done']?.toString() ?? '', x: 32, y: 415, width: 245, height: 191, fontSize: 10),
        OverlayField.text(data['problems_faced']?.toString() ?? '', x: 305, y: 415, width: 155, height: 185, fontSize: 10),
        OverlayField.text(data['resources_used']?.toString() ?? '', x: 490, y: 415, width: 115, height: 185, fontSize: 10),
      ].whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1]);
  }

  /// Generates the ST-FORM 04 overlay by mapping the provided data and attendance to coordinates.
  static Future<Uint8List> generateStForm04({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final List<dynamic> attendance = data['attendance'] as List<dynamic>? ?? [];
    
    final List<OverlayField?> fields = [
      // Single-line Info
      OverlayField.text(student.name, x: 164, y: 210),
      OverlayField.text(student.universityId, x: 460, y: 210),
      OverlayField.text(data['company_name']?.toString() ?? '', x: 250, y: 235),
    ];

    // Grid Logic (Nested Loops)
    for (int i = 0; i < attendance.length && i < 40; i++) {
      final record = attendance[i];
      final String dateStr = record['date']?.toString() ?? '';
      final String reasonStr = record['reason']?.toString() ?? '';
      // We assume if they attended, they get a stamp. Otherwise left blank or reason filled.
      final bool present = record['present'] == true || record['present'] == 'true';
      final String signature = present ? '✔' : '';

      if (i < 20) {
        // Left Grid (Weeks 1-4)
        double startY = 277 + (i * 24.6);
        fields.add(OverlayField.text(dateStr, x: 117, y: startY, fontSize: 9));
        fields.add(OverlayField.text(signature, x: 117 + 65, y: startY, fontSize: 9));
        fields.add(OverlayField.text(reasonStr, x: 117 + 130, y: startY, fontSize: 9));
      } else {
        // Right Grid (Weeks 5-8)
        int rightIndex = i - 20;
        double startY = 276 + (rightIndex * 24.8);
        fields.add(OverlayField.text(dateStr, x: 392, y: startY, fontSize: 9));
        fields.add(OverlayField.text(signature, x: 392 + 66, y: startY, fontSize: 9));
        fields.add(OverlayField.text(reasonStr, x: 392 + 132, y: startY, fontSize: 9));
      }
    }

    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_04_p1.png',
      fields: fields.whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1]);
  }

  /// Generates the ST-FORM 07 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateStForm07({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    final List<OverlayField?> fields = [
      // Header Info
      OverlayField.text(student.name, x: 280, y: 177),
      OverlayField.text(student.universityId, x: 650, y: 177),
      OverlayField.text(data['company_name']?.toString() ?? '', x: 280, y: 202),
      OverlayField.text('Digital Signature: ${student.name}', x: 283, y: 232, fontSize: 10),
      OverlayField.text(dateFormat.format(DateTime.now()), x: 680, y: 231),
    ];

    // 40-Square Grid Logic (Ratings)
    // Assuming data['ratings'] is a List<int> of size 8
    final List<int> ratings = (data['ratings'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList() ?? [];
    for (int i = 0; i < ratings.length && i < 8; i++) {
      int ratingValue = ratings[i];
      if (ratingValue >= 1 && ratingValue <= 5) {
        double targetX = (582 + ((ratingValue - 1) * 60)) - 4;
        double targetY = (293 + (i * 14)) - 6;
        fields.add(OverlayField.text('✔', x: targetX, y: targetY, fontSize: 12, fontWeight: pw.FontWeight.bold));
      }
    }

    // Boolean Checkboxes (Yes / No / Uncertain)
    final String recommend = data['recommend_company']?.toString().toLowerCase() ?? '';
    if (recommend == 'yes') {
      fields.add(OverlayField.text('✔', x: 533 - 4, y: 432 - 6, fontSize: 12, fontWeight: pw.FontWeight.bold));
    } else if (recommend == 'no') {
      fields.add(OverlayField.text('✔', x: 666 - 4, y: 430 - 6, fontSize: 12, fontWeight: pw.FontWeight.bold));
    } else if (recommend == 'uncertain') {
      fields.add(OverlayField.text('✔', x: 793 - 4, y: 432 - 6, fontSize: 12, fontWeight: pw.FontWeight.bold));
    }

    // Comments Section (Multiline Bounding Box)
    fields.add(OverlayField.text(
      data['comments']?.toString() ?? '', 
      x: 106, 
      y: 463, 
      width: 747, 
      height: 51, 
      fontSize: 11
    ));

    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_07_p1.png',
      fields: fields.whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1]);
  }

  /// Generates the TA-FORM 01 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateTaForm01({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    final List<OverlayField?> fields = [
      // Header Info
      OverlayField.text(student.name, x: 167, y: 267),
      OverlayField.text(student.universityId, x: 467, y: 270),
      OverlayField.text(data['company_name']?.toString() ?? '', x: 228, y: 293),
    ];

    // Weekly Tasks Grid Logic
    final List<dynamic> weeklyTasks = data['weekly_tasks'] as List<dynamic>? ?? [];
    for (int i = 0; i < weeklyTasks.length && i < 8; i++) {
      String taskText = weeklyTasks[i]?.toString() ?? '';
      
      if (i < 4) {
        // Weeks 1-4
        double startY = 337 + (i * 88.25);
        fields.add(OverlayField.text(
          taskText, 
          x: 112, 
          y: startY, 
          width: 200, 
          height: 88, 
          fontSize: 10
        ));
      } else {
        // Weeks 5-8
        int rightIndex = i - 4;
        double startY = 332 + (rightIndex * 89.75);
        fields.add(OverlayField.text(
          taskText, 
          x: 384, 
          y: startY, 
          width: 201, 
          height: 89, 
          fontSize: 10
        ));
      }
    }

    // Footer & Signatures
    String supervisorName = data['supervisor_name']?.toString() ?? student.supervisor;
    fields.add(OverlayField.text(supervisorName, x: 162, y: 732));
    fields.add(OverlayField.text('Digital Stamp: $supervisorName', x: 209, y: 713, fontSize: 10));
    fields.add(OverlayField.text(data['supervisor_position']?.toString() ?? '', x: 436, y: 732));
    fields.add(OverlayField.text(dateFormat.format(DateTime.now()), x: 442, y: 772));

    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/ta_form_01_p1.png',
      fields: fields.whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1]);
  }

  /// Generates the TA-FORM 04 overlay by mapping the provided survey data.
  static Future<Uint8List> generateTaForm04({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    // WARNING: These coordinates are placeholders.
    // Replace with the exact X positions of the 1, 2, 3, 4, 5 columns.
    final likertXColumns = [200.0, 250.0, 300.0, 350.0, 400.0];

    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/ta_form_04_p1.png',
      fields: [
        // Header Info
        OverlayField.text(student.name, x: 150, y: 700),
        OverlayField.text(data['students_gender'], x: 150, y: 670),
        OverlayField.text(data['training_agency'], x: 150, y: 640),
        OverlayField.text(data['department'], x: 150, y: 610),
        
        // Yes/No Checkboxes
        OverlayField.checkbox(data['trained_past_2_years'], x: 150, y: 580),
        OverlayField.checkbox(data['currently_training'], x: 150, y: 550),

        // Domain 1: Training Application
        OverlayField.likert(data['Application process was clear'], xColumns: likertXColumns, y: 400),
        OverlayField.likert(data['Application process was efficient'], xColumns: likertXColumns, y: 380),

        // Domain 2: Communication
        OverlayField.text(data['communication_freq'], x: 150, y: 340), // Dropdown value mapped as text
        OverlayField.likert(data['Issues encountered relating to the trainee were resolved effectively'], xColumns: likertXColumns, y: 320),
      ].whereType<OverlayField>().toList(),
    );

    final page2 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/ta_form_04_p2.png',
      fields: [
        // Domain 3: Training Program
        OverlayField.text(data['provided_manual'], x: 150, y: 700), // Dropdown Yes/No
        OverlayField.likert(data['The training manual was clear'], xColumns: likertXColumns, y: 670),
        OverlayField.likert(data['The training manual included relevant information needed for guiding the trainees'], xColumns: likertXColumns, y: 640),

        // Domain 4: Assessment
        OverlayField.text(data['provided_forms'], x: 150, y: 600),
        OverlayField.likert(data['Trainee Assessment and Evaluation forms were clear'], xColumns: likertXColumns, y: 570),

        // Domain 5: Student Evaluation
        OverlayField.likert(data['IAU students were ready for training'], xColumns: likertXColumns, y: 520),
        OverlayField.likert(data['IAU students demonstrated professionalism while undertaking training'], xColumns: likertXColumns, y: 490),

        // Comments Section
        OverlayField.text(data['best_quality'], x: 100, y: 400),
        OverlayField.text(data['suggestions'], x: 100, y: 350),

        // Supervisor Signature Overlay
        OverlayField.text(
          'Digitally Signed by: ${student.supervisor}\nDate: ${dateFormat.format(DateTime.now())}', 
          x: 300, y: 150, fontSize: 10,
        ),
      ].whereType<OverlayField>().toList(),
    );

    return PdfOverlayService.generateOverlayPdf(pagesData: [page1, page2]);
  }
}
