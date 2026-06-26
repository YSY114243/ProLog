import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/daily_log.dart';
import '../models/challenge.dart';

// ── Student metadata ──────────────────────────────────────────────────────────

/// Holds the student info that appears on the PDF cover page.
class StudentInfo {
  final String name;
  final String universityId;
  final String major;
  final String universityName;
  final String company;
  final String supervisor;
  final String? customLogoUrl;

  const StudentInfo({
    required this.name,
    required this.universityId,
    required this.major,
    required this.universityName,
    required this.company,
    required this.supervisor,
    this.customLogoUrl,
  });

  static const empty = StudentInfo(
    name: '',
    universityId: '',
    major: '',
    universityName: '',
    company: '',
    supervisor: '',
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
                pw.SizedBox(height: 32),

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
      margin: const pw.EdgeInsets.only(top: 50),
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
}

