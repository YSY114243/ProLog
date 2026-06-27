import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'pdf_overlay_service.dart';
import 'pdf_service.dart';

class PdfOverlayMapper {
  /// Generates the ST-FORM 02 overlay by mapping the provided data to coordinates.
  static Future<Uint8List> generateStForm02({
    required StudentInfo student,
    required Map<String, dynamic> data,
  }) async {
    final dateFormat = DateFormat('dd MMM yyyy');
    DateTime? startDate;
    if (data['start_date'] != null) {
      startDate = DateTime.tryParse(data['start_date'].toString());
    }
    
    // WARNING: These coordinates (x, y) are placeholders. 
    // They must be adjusted to align with the blanks on 'st_form_02_p1.png'.
    final page1 = PdfPageOverlayData(
      backgroundAssetPath: 'assets/images/st_form_02_p1.png',
      fields: [
        // Student Info
        OverlayField.text(student.name, x: 150, y: 700),
        OverlayField.text(student.universityId, x: 150, y: 670),
        OverlayField.text(student.major, x: 150, y: 640),
        
        // Form Data
        OverlayField.text(data['company_name'], x: 150, y: 610),
        OverlayField.text(startDate != null ? dateFormat.format(startDate) : '', x: 150, y: 580),
        OverlayField.text(data['supervisor_name'], x: 150, y: 550),
        OverlayField.text(data['supervisor_position'], x: 150, y: 520),
        OverlayField.text(data['supervisor_mobile'], x: 150, y: 490),
        OverlayField.text(data['supervisor_email'], x: 150, y: 460),
        OverlayField.text(data['address'], x: 150, y: 430),

        // Signatures (Placed over the designated stamp areas)
        OverlayField.text(
          'Digitally Signed by: ${student.name}\nID: ${student.universityId}\nDate: ${dateFormat.format(DateTime.now())}', 
          x: 100, y: 200, fontSize: 10,
        ),
        OverlayField.text(
          'Digitally Signed by: ${data['supervisor_name'] ?? student.supervisor}\nEmail: ${data['supervisor_email'] ?? 'System Auth'}\nDate: ${dateFormat.format(DateTime.now())}', 
          x: 400, y: 200, fontSize: 10,
        ),
      ].whereType<OverlayField>().toList(),
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
