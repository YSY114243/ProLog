import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/daily_log.dart';
import '../models/challenge.dart';
import 'pdf_form_delegates.dart';

// ── Student metadata ──────────────────────────────────────────────────────────

/// Holds the student info that appears on the PDF cover page.
class StudentInfo {
  final String name;
  final String universityId;
  final String major;
  final String universityName;
  final String company;
  final String supervisor;
  final String? supervisorEmail;
  final String? customLogoUrl;

  const StudentInfo({
    required this.name,
    required this.universityId,
    required this.major,
    required this.universityName,
    required this.company,
    required this.supervisor,
    this.supervisorEmail,
    this.customLogoUrl,
  });

  static const empty = StudentInfo(
    name: '',
    universityId: '',
    major: '',
    universityName: '',
    company: '',
    supervisor: '',
    supervisorEmail: '',
    customLogoUrl: null,
  );
}

// ── PDF brand colours (0.0–1.0 components) ───────────────────────────────────

class _C {
  static const dark      = PdfColor(0.102, 0.102, 0.180); // #1A1A2E
  static const muted     = PdfColor(0.361, 0.420, 0.478); // #5C6B7A
  static const cardBord  = PdfColor(0.816, 0.929, 0.941); // #D0ECF0
  static const green     = PdfColor(0.180, 0.490, 0.196); // Field Work
  static const blue      = PdfColor(0.082, 0.392, 0.745); // Office Work
  static const purple    = PdfColor(0.416, 0.098, 0.608); // Software
  static const divider   = PdfColor(0.867, 0.910, 0.922);
}

// ── PdfService ────────────────────────────────────────────────────────────────

/// Singleton service that generates and downloads the internship PDF report.
///
/// Usage:
/// ```dart
/// final bytes = await PdfService.instance.generateInternshipReport(
///   logs: allLogs,
///   student: StudentInfo(name: 'Ahmed', universityId: '123', company: 'ACME'),
/// );
/// await PdfService.instance.downloadPdf(bytes, 'InternLog_Report.pdf');
/// ```
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();



  /// Attempts to load the custom logo from the given URL.
  Future<pw.MemoryImage?> _loadCustomLogo(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        return pw.MemoryImage(resp.bodyBytes);
      }
    } catch (_) {
      // Fallback cleanly if the image fails to load
    }
    return null;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Builds the full internship report PDF and returns the raw bytes.
  ///
  /// [logs]    — All daily log entries to include in the table.
  /// [student] — Student metadata for the cover page.
  Future<Uint8List> generateInternshipReport({
    required List<DailyLog> logs,
    required StudentInfo student,
    List<Challenge> challenges = const [],
  }) async {
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();
    final customLogo = await _loadCustomLogo(student.customLogoUrl);

    final Map<String, pw.MemoryImage> appendixImages = {};
    for (final log in logs) {
      if (log.imageUrl != null && log.imageUrl!.isNotEmpty && !appendixImages.containsKey(log.imageUrl)) {
        try {
          final res = await http.get(Uri.parse(log.imageUrl!)).timeout(const Duration(seconds: 15));
          if (res.statusCode == 200) {
            appendixImages[log.imageUrl!] = pw.MemoryImage(res.bodyBytes);
          }
        } catch (e) {
          print('Failed to fetch image for appendix: $e');
        }
      }
    }

    final theme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
      fontFallback: [arabicFont, arabicBold],
    );

    final dateFormat = DateFormat('MMM dd, yyyy');
    final sorted     = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final dateFrom   = sorted.isNotEmpty ? sorted.first.date : DateTime.now();
    final dateTo     = sorted.isNotEmpty ? sorted.last.date  : DateTime.now();

    final doc = pw.Document(
      title:   'Internship Training Report',
      author:  student.name.isNotEmpty ? student.name : 'InternLog User',
      creator: 'InternLog – Professional Log',
    );

    // Helper for watermark background (removed to ensure readability)
    pw.Widget buildWatermark(pw.Context ctx) => pw.Container();

    // ── Cover page ───────────────────────────────────────────────────────────
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: buildWatermark,
        ),
        build: (ctx) => _buildCoverPage(
          student, logs, dateFrom, dateTo, dateFormat, customLogo,
        ),
      ),
    );

    // ── Log table (multi-page) ────────────────────────────────────────────
    if (logs.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            buildBackground: buildWatermark,
          ),
          header: (ctx) => _pageHeader(ctx, student, customLogo),
          footer: (ctx) => _pageFooter(ctx, student),
          build:  (ctx) => [
            ..._buildLogTable(logs, dateFormat),
            if (challenges.isEmpty) _buildSignatureBlock(),
          ],
        ),
      );
    }

    // ── Challenges & Lessons Learned (multi-page) ─────────────────────────
    if (challenges.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            buildBackground: buildWatermark,
          ),
          header: (ctx) => _challengesPageHeader(ctx),
          footer: (ctx) => _pageFooter(ctx, student),
          build:  (ctx) => [
            ..._buildChallengesTable(challenges, dateFormat),
            _buildSignatureBlock(),
          ],
        ),
      );
    }

    // ── Appendix: Site Progress Photos (multi-page) ─────────────────────────
    if (appendixImages.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            buildBackground: buildWatermark,
          ),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Appendix: Site Progress Photos',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(height: 2, color: PdfColors.black),
              pw.SizedBox(height: 14),
            ],
          ),
          footer: (ctx) => _pageFooter(ctx, student),
          build: (ctx) {
            final widgets = <pw.Widget>[];
            for (final log in sorted) {
              if (log.imageUrl != null && appendixImages.containsKey(log.imageUrl)) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 30),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          height: 300,
                          child: pw.Image(appendixImages[log.imageUrl!]!, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Photo from ${dateFormat.format(log.date)}',
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            return widgets;
          },
        ),
      );
    }

    return doc.save();
  }

  /// Triggers a browser download (web) or share sheet (mobile/desktop).
  Future<void> downloadPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ── Cover page ────────────────────────────────────────────────────────────

  pw.Widget _buildCoverPage(
    StudentInfo student,
    List<DailyLog> logs,
    DateTime dateFrom,
    DateTime dateTo,
    DateFormat fmt,
    pw.MemoryImage? customLogo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Top line ──────────────────────────────────────────
        pw.Container(
          height: 2,
          color: PdfColors.black,
        ),

        // ── White content area ───────────────────────────────────────────
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(56, 52, 56, 36),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                pw.SizedBox(height: 10),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Main title
                          pw.Text(
                            'Summer Training Documentation',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize:  16,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            'Record of Professional Practice',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize:  14,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            student.major.isNotEmpty ? student.major : 'Engineering',
                            style: pw.TextStyle(
                              fontStyle: pw.FontStyle.italic,
                              fontSize: 13,
                              color: PdfColors.black,
                            ),
                          ),
                        ]
                      ),
                    ),
                    if (customLogo != null)
                      pw.Container(
                        height: 50,
                        child: pw.Image(customLogo),
                      ),
                  ],
                ),

                pw.SizedBox(height: 40),
                pw.Divider(color: _C.cardBord, thickness: 1),
                pw.Spacer(),

                // Student info card
                _coverInfoCard(student, logs, dateFrom, dateTo, fmt),

                pw.Spacer(),

                // Generated timestamp
                pw.Text(
                  'Generated by InternLog on '
                  '${DateFormat('MMMM d, yyyy \'at\' HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 8,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Cyan accent bottom bar ───────────────────────────────────────
        pw.Container(height: 6, color: PdfColors.black),
      ],
    );
  }

  pw.Widget _coverInfoCard(
    StudentInfo student,
    List<DailyLog> logs,
    DateTime dateFrom,
    DateTime dateTo,
    DateFormat fmt,
  ) {
    String fill(String v, [String blank = '________________________________']) =>
        v.isNotEmpty ? v : blank;

    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section label
          pw.Text(
            'STUDENT INFORMATION',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize:      8,
              color: PdfColors.black,
              letterSpacing: 1.4,
            ),
          ),
          pw.SizedBox(height: 16),

          // Info rows
          _infoRow('Student Name',     fill(student.name)),
          _infoRow('University ID',    fill(student.universityId)),
          _infoRow('Major',            fill(student.major)),
          _infoRow('University Name',  fill(student.universityName)),
          _infoRow('Training Company', fill(student.company)),
          _infoRow('Supervisor Name',  fill(student.supervisor)),
          _infoRow(
            'Training Period',
            '${fmt.format(dateFrom)} to ${fmt.format(dateTo)}',
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Text(
            ':  ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.normal,
              fontSize: 9.5,
              color: PdfColors.black,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── Page header / footer ──────────────────────────────────────────────────

  pw.Widget _pageHeader(pw.Context ctx, StudentInfo student, pw.MemoryImage? customLogo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Daily Activity Log',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: PdfColors.black,
              ),
            ),
            if (customLogo != null)
              pw.Container(
                height: 30,
                child: pw.Image(customLogo),
              )
            else
              pw.Text(
                student.name.isNotEmpty
                    ? student.name
                    : 'Internship Student',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 9,
                  color: PdfColors.black,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, color: PdfColors.black),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pw.Widget _pageFooter(pw.Context ctx, StudentInfo student) {
    return pw.Column(
      children: [
        pw.Container(height: 0.8, color: _C.divider),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by InternLog - Professional Log for ${student.major.isNotEmpty ? student.major : 'Engineering'}',
              style: pw.TextStyle(
                fontStyle: pw.FontStyle.italic,
                fontSize: 7.5,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Log table ─────────────────────────────────────────────────────────────

  List<pw.Widget> _buildLogTable(List<DailyLog> logs, DateFormat fmt) {
    const kDate = 68.0;
    const kType = 72.0;

    // Detect Arabic characters (U+0600–U+06FF range)
    bool hasArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

    // Table header
    final header = pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      children: [
        _thCell('DATE'),
        _thCell('TASK TYPE'),
        _thCell('DESCRIPTION'),
        _thCell('ISSUES & SOLUTIONS'),
      ],
    );

    // Data rows
    final rows = logs.asMap().entries.map((e) {
      final log = e.value;
      final bg  = PdfColors.white;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          // Date
          _tdCell(
            fmt.format(log.date),
            isBold: true,
            color: PdfColors.black,
          ),
          // Task type with coloured dot
          _taskTypeCell(log.taskType),
          // Description — RTL if Arabic
          _tdCell(
            log.description,
            direction: hasArabic(log.description)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
          ),
          // Issues & Solutions + Image — RTL if Arabic
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: pw.Column(
              crossAxisAlignment: hasArabic(log.issuesFound) ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
              children: [
                pw.Directionality(
                  textDirection: hasArabic(log.issuesFound) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  child: pw.Text(
                    log.issuesFound.trim().isEmpty ? '—' : log.issuesFound,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.black,
                      lineSpacing: 1.5,
                    ),
                  ),
                ),
                if (log.imageUrl != null && log.imageUrl!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '(Photo in Appendix)',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.black,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      );
    }).toList();

    return [
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(kDate),
          1: const pw.FixedColumnWidth(kType),
          2: const pw.FlexColumnWidth(3),
          3: const pw.FlexColumnWidth(2),
        },
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        children: [header, ...rows],
      ),
    ];
  }

  pw.Widget _thCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 8.5,
          color: PdfColors.black,
          lineSpacing: 1.5,
        ),
      ),
    );
  }

  // ── Signature Block ───────────────────────────────────────────────────────

  pw.Widget _buildSignatureBlock() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 80),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Supervisor Sign-off',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: PdfColors.black),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Supervisor Name & Signature: .................................................',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'Company Stamp: ........................................',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
        ],
      ),
    );
  }

  pw.Widget _tdCell(
    String text, {
    bool isBold = false,
    bool dimmed = false,
    PdfColor? color,
    pw.TextDirection direction = pw.TextDirection.ltr,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Directionality(
        textDirection: direction,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font:        isBold ? pw.Font.helveticaBold() : null, // Uses default theme font
            fontSize:    8,
            color:       dimmed ? _C.muted : (color ?? _C.dark),
            lineSpacing: 1.5,
          ),
          maxLines: 6,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  pw.Widget _taskTypeCell(TaskType type) {
    final color = _taskColor(type);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              type.label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7.5,
                color:    color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _taskColor(TaskType type) {
    switch (type) {
      case TaskType.fieldWork:  return _C.green;
      case TaskType.officeWork: return _C.blue;
      case TaskType.software:   return _C.purple;
    }
  }

  // ── Challenges section ──────────────────────────────────────────────────

  pw.Widget _challengesPageHeader(pw.Context ctx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Challenges & Lessons Learned',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 14,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, color: PdfColors.black),
        pw.SizedBox(height: 14),
      ],
    );
  }

  List<pw.Widget> _buildChallengesTable(List<Challenge> challenges, DateFormat fmt) {
    final sortedChallenges = [...challenges]..sort((a, b) => a.date.compareTo(b.date));

    final header = pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      children: [
        _thCell('DATE'),
        _thCell('PROBLEM'),
        _thCell('ACTION TAKEN & LESSONS LEARNED'),
      ],
    );

    final rows = sortedChallenges.asMap().entries.map((e) {
      final c = e.value;
      final bg = PdfColors.white;

      final combined = [
        if (c.resolution.trim().isNotEmpty) 'Action:\n${c.resolution}',
        if (c.lessonsLearned.trim().isNotEmpty) 'Learnings:\n${c.lessonsLearned}',
      ].join('\n\n');

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          _tdCell(fmt.format(c.date), isBold: true, color: PdfColors.black),
          _tdCell(c.problem),
          _tdCell(combined.trim().isEmpty ? '—' : combined, dimmed: combined.trim().isEmpty),
        ],
      );
    }).toList();

    return [
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(68),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(3),
        },
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        children: [header, ...rows],
      ),
    ];
  }

  // ── Official Forms (ST-FORM 02 & TA-FORM 03) ─────────────────────────────

  Future<Uint8List> generateStForm02Pdf({
    required StudentInfo student,
    required DateTime trainingStartDate,
  }) async {
    final doc = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();
    final theme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
      fontFallback: [arabicFont, arabicBold],
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
        ),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'ST-FORM 02: Starting Date Form',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 48),
              _buildFormRow('Student Name:', student.name),
              pw.SizedBox(height: 16),
              _buildFormRow('Student ID:', student.universityId),
              pw.SizedBox(height: 16),
              _buildFormRow('Department / Major:', student.major),
              pw.SizedBox(height: 16),
              _buildFormRow('Training Start Date:', dateFormat.format(trainingStartDate)),
              pw.SizedBox(height: 16),
              _buildFormRow('Company Name:', student.company),
              pw.SizedBox(height: 16),
              _buildFormRow('Company Supervisor:', student.supervisor),
              if (student.supervisorEmail != null && student.supervisorEmail!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                _buildFormRow('Supervisor Email:', student.supervisorEmail!),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Student Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 40),
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Supervisor Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 40),
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildFormRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Future<Uint8List> generateTaForm03Pdf({
    required StudentInfo student,
    required Map<String, dynamic> evaluation,
  }) async {
    final doc = pw.Document();
    
    pw.Font? formalFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/times.ttf');
      formalFont = pw.Font.ttf(fontData);
    } catch (_) {
      formalFont = pw.Font.times();
    }

    final theme = pw.ThemeData.withFont(
      base: formalFont,
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    pw.Widget logoWidget;
    try {
      final svgData = await rootBundle.loadString('assets/images/iau_logo.svg');
      logoWidget = pw.SvgImage(svg: svgData, width: 120);
    } catch (_) {
      logoWidget = pw.SizedBox(height: 60);
    }

    final criteria = [
      {'label': 'Enthusiasm (ABET 4)', 'key': 'enthusiasm'},
      {'label': 'Delivering accurate work (ABET 4)', 'key': 'delivering_accurate_work'},
      {'label': 'Dealing with new systems (ABET 7)', 'key': 'dealing_with_new_systems'},
      {'label': 'Initiative (ABET 5)', 'key': 'initiative'},
      {'label': 'Dependability (ABET 4)', 'key': 'dependability'},
      {'label': 'Learning and searching (ABET 7)', 'key': 'learning_and_searching'},
      {'label': 'Judgment and decision making (ABET 4)', 'key': 'judgment_and_decision_making'},
      {'label': 'Effective relations (ABET 5)', 'key': 'effective_relations'},
      {'label': 'Reporting and presenting (ABET 3)', 'key': 'reporting_and_presenting'},
      {'label': 'Attendance and punctuality (ABET 4)', 'key': 'attendance_and_punctuality'},
    ];

    final int totalScore = evaluation['total_score'] ?? 0;

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: logoWidget),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'TA-FORM 03: Supervisor Evaluation',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 24),
              
              // Table 1: Student Information
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ID Number:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student.universityId)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Company:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student.company)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Supervisor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(student.supervisor)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              
              // Table 2: Evaluation Scale
              pw.Table(
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
                        child: pw.Text('Evaluation Criteria', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('2', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('3', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('4', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                  ...criteria.map((c) {
                    final int score = int.tryParse(evaluation[c['key']]?.toString() ?? '0') ?? 0;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(c['label'] as String, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 1 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 1 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 2 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 2 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 3 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 3 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 4 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 4 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 5 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 5 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$totalScore / 50', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Supervisor Signature & Stamp', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 30),
                      pw.Container(width: 200, height: 1, color: PdfColors.black),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> generateTaForm04Pdf({
    required StudentInfo student,
    required Map<String, dynamic> survey,
  }) async {
    final doc = pw.Document();
    
    pw.Font? formalFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/times.ttf');
      formalFont = pw.Font.ttf(fontData);
    } catch (_) {
      formalFont = pw.Font.times();
    }

    final theme = pw.ThemeData.withFont(
      base: formalFont,
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    pw.Widget logoWidget;
    try {
      final svgData = await rootBundle.loadString('assets/images/iau_logo.svg');
      logoWidget = pw.SvgImage(svg: svgData, width: 120);
    } catch (_) {
      logoWidget = pw.SizedBox(height: 60);
    }

    final domains = [
      {
        'title': 'Training Application',
        'questions': [
          {'label': 'Application process was clear', 'key': 'app_clear'},
          {'label': 'Application process was efficient', 'key': 'app_efficient'},
        ],
      },
      {
        'title': 'Communication',
        'questions': [
          {'label': 'Communication was prompt', 'key': 'comm_prompt'},
          {'label': 'Information provided was helpful', 'key': 'comm_helpful'},
        ],
      },
      {
        'title': 'Training Program',
        'questions': [
          {'label': 'Program met expectations', 'key': 'prog_met_expectations'},
          {'label': 'Would recommend to others', 'key': 'prog_recommend'},
        ],
      },
    ];

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: logoWidget),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'TA-FORM 04: Agency Survey',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 24),
              
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Training Agency:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(survey['training_agency']?.toString() ?? student.company)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Students Gender:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(survey['students_gender']?.toString() ?? '')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Number of students trained:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(survey['number_of_students']?.toString() ?? '')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              
              pw.Table(
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
                        child: pw.Text('Evaluation Domains', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('2', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('3', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('4', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    ],
                  ),
                  for (final domain in domains) ...[
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(domain['title'] as String, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      ],
                    ),
                    for (final q in (domain['questions'] as List<Map<String, Object>>)) ...[
                      () {
                        final int score = int.tryParse(survey[q['key']]?.toString() ?? '0') ?? 0;
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16, top: 6, bottom: 6, right: 6),
                              child: pw.Text(q['label'] as String, style: const pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 1 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 1 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 2 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 2 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 3 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 3 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 4 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 4 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(score == 5 ? 'X' : '', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: score == 5 ? pw.FontWeight.bold : pw.FontWeight.normal))),
                          ],
                        );
                      }()
                    ]
                  ],
                ],
              ),
              
              pw.Spacer(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Agency Representative Signature & Stamp', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 30),
                      pw.Container(width: 250, height: 1, color: PdfColors.black),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
  Future<pw.Widget> _buildAcademicHeader(String title) async {
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
            logoImage != null
                ? pw.Image(logoImage, width: 60, height: 60)
                : pw.SizedBox(width: 60, height: 60),
            pw.Text(
              'College of Engineering\nImam Abdulrahman bin Faisal University',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 16),
      ],
    );
  }

  pw.Widget _buildAcademicFooter() {
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

  Future<Uint8List> generateTaForm01Pdf({
    required StudentInfo student,
    required Map<String, dynamic> formData,
  }) async {
    final doc = pw.Document();

    pw.Font? formalFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/times.ttf');
      formalFont = pw.Font.ttf(fontData);
    } catch (_) {
      formalFont = pw.Font.times();
    }

    final theme = pw.ThemeData.withFont(
      base: formalFont,
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    pw.Widget logoWidget;
    try {
      final svgData = await rootBundle.loadString('assets/images/iau_logo.svg');
      logoWidget = pw.SvgImage(svg: svgData, width: 120);
    } catch (_) {
      logoWidget = pw.SizedBox(height: 60);
    }

    final activities = List.generate(8, (i) => formData['week_${i + 1}']?.toString() ?? '');

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: logoWidget),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'TRAINING PLAN (TA-FORM 01)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 24),
              
              // Table 1: Student Information
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('ID Number:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.universityId)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Company Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.company)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              
              // Table 2: 8-Week Split Table
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Week', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Expected Training Activities', textAlign: pw.TextAlign.left, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Week', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Expected Training Activities', textAlign: pw.TextAlign.left, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  for (int i = 0; i < 4; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Week #${i + 1}', textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(activities[i], textAlign: pw.TextAlign.left)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Week #${i + 5}', textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(activities[i + 4], textAlign: pw.TextAlign.left)),
                      ],
                    ),
                ],
              ),
              
              pw.SizedBox(height: 32),
              
              // Table 3: Supervisor Info & Signatures
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Position:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Supervisor')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Supervisor Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.supervisor)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Signature:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('_________________')),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
              pw.Text(
                'Supervisor or company representative should send this form to the Training Coordinator in the university via email within the first week of training.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> generateStudentReportPdf({
    required StudentInfo student,
    required String reportType,
    required Map<String, dynamic> reportData,
  }) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    final formId = reportType == 'Midterm' ? 'ST-FORM 03' : 'ST-FORM 07/08';

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(formId, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text('$reportType Progress Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (ctx) => [
          _buildFormRow('Student Name:', student.name),
          pw.SizedBox(height: 8),
          _buildFormRow('University ID:', student.universityId),
          pw.SizedBox(height: 8),
          _buildFormRow('Company:', student.company),
          pw.SizedBox(height: 24),
          
          pw.Text('Tasks Completed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
            child: pw.Text(reportData['tasks_completed']?.toString() ?? '', style: const pw.TextStyle(fontSize: 12)),
          ),
          
          pw.SizedBox(height: 24),
          pw.Text('Skills Acquired', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
            child: pw.Text(reportData['skills_acquired']?.toString() ?? '', style: const pw.TextStyle(fontSize: 12)),
          ),
          
          pw.SizedBox(height: 48),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Student Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Supervisor Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<Uint8List> generateGenericFormPdf({
    required StudentInfo student,
    required String formId,
    required Map<String, dynamic> formData,
  }) async {
    if (formId.startsWith('ST-FORM 0')) {
      return PdfFormDelegates.generateForm(student, formId, formData);
    }
    if (formId == 'TA-FORM 03') {
      return generateTaForm03Pdf(student: student, evaluation: formData);
    }
    if (formId == 'TA-FORM 04') {
      return generateTaForm04Pdf(student: student, survey: formData);
    }
    if (formId == 'TA-FORM 01') {
      return generateTaForm01Pdf(student: student, formData: formData);
    }

    final doc = pw.Document();

    pw.Font? formalFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/times.ttf');
      formalFont = pw.Font.ttf(fontData);
    } catch (_) {
      formalFont = pw.Font.times();
    }

    final theme = pw.ThemeData.withFont(
      base: formalFont,
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    final header = await _buildAcademicHeader('COOP TRAINING - $formId');

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        header: (ctx) => header,
        footer: (ctx) => _buildAcademicFooter(),
        build: (ctx) => [
          _buildFormRow('Student Name:', student.name),
          pw.SizedBox(height: 8),
          _buildFormRow('University ID:', student.universityId),
          pw.SizedBox(height: 8),
          _buildFormRow('Major:', student.major),
          pw.SizedBox(height: 24),
          
          ...formData.entries.map((e) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(e.key.replaceAll('_', ' ').toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 12)),
                ),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );

    return doc.save();
  }
}
