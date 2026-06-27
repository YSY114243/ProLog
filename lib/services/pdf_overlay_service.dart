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
