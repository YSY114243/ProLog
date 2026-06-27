import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Represents a widget overlay at a specific coordinate (x, y).
class OverlayField {
  final double x;
  final double y;
  final pw.Widget child;

  const OverlayField({
    required this.x,
    required this.y,
    required this.child,
  });

  /// Safely converts Strings, ints, or doubles into a text overlay.
  static OverlayField? text(dynamic value, {required double x, required double y, double fontSize = 12, pw.FontWeight fontWeight = pw.FontWeight.normal}) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return OverlayField(
      x: x,
      y: y,
      child: pw.Text(
        value.toString(),
        style: pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
    );
  }

  /// Evaluates boolean or boolean-like string. Prints 'X' if true, omits if false.
  static OverlayField? checkbox(dynamic value, {required double x, required double y, double fontSize = 12}) {
    bool isChecked = false;
    if (value is bool) {
      isChecked = value;
    } else if (value is String) {
      final v = value.toLowerCase().trim();
      isChecked = (v == 'true' || v == 'yes' || v == '1');
    } else if (value is num) {
      isChecked = value == 1;
    }

    if (!isChecked) return null;
    return OverlayField(
      x: x,
      y: y,
      child: pw.Text('X', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
    );
  }

  /// Places an 'X' mark at the correct column coordinate for a 1-5 Likert scale.
  static OverlayField? likert(dynamic value, {required List<double> xColumns, required double y, double fontSize = 12}) {
    if (value == null) return null;
    final int score = (num.tryParse(value.toString()) ?? 0).toInt();
    
    // Ensure score is within valid range and we have enough column coordinates provided
    if (score < 1 || score > 5 || xColumns.length < 5) return null;

    // xColumns should contain exactly 5 coordinates for scores 1, 2, 3, 4, 5 respectively.
    return OverlayField(
      x: xColumns[score - 1],
      y: y,
      child: pw.Text('X', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
    );
  }
}

/// Represents the data needed for a single page in a multi-page PDF overlay.
class PdfPageOverlayData {
  final String backgroundAssetPath;
  final List<OverlayField> fields;

  const PdfPageOverlayData({
    required this.backgroundAssetPath,
    required this.fields,
  });
}

/// Service that overlays text or widgets onto fixed background images (e.g., official forms).
class PdfOverlayService {
  
  /// Generates a multi-page PDF document by overlaying widgets onto background images.
  /// 
  /// Takes a list of [PdfPageOverlayData]. For each item, it creates a new PDF page
  /// using the provided image as the background, and positions the given fields using a Stack.
  static Future<Uint8List> generateOverlayPdf({
    required List<PdfPageOverlayData> pagesData,
  }) async {
    final doc = pw.Document();

    for (final pageData in pagesData) {
      // Load the background image for this specific page
      final bgData = await rootBundle.load(pageData.backgroundAssetPath);
      final bgImage = pw.MemoryImage(bgData.buffer.asUint8List());

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // No margins, let the image take full space
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(bgImage, fit: pw.BoxFit.fill),
            );
          },
          build: (pw.Context context) {
            // Overlay the fields using absolute coordinates
            return pw.Stack(
              children: pageData.fields.map((field) {
                return pw.Positioned(
                  left: field.x,
                  top: field.y,
                  child: field.child,
                );
              }).toList(),
            );
          },
        ),
      );
    }

    return doc.save();
  }
}
