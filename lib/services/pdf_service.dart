import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/daily_log.dart';

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
  static const cyan      = PdfColor(0.000, 0.737, 0.831); // #00BCD4
  static const teal      = PdfColor(0.000, 0.588, 0.533); // #009688
  static const dark      = PdfColor(0.102, 0.102, 0.180); // #1A1A2E
  static const muted     = PdfColor(0.361, 0.420, 0.478); // #5C6B7A
  static const bgLight   = PdfColor(0.878, 0.973, 0.984); // #E0F7FA
  static const cardBg    = PdfColor(0.922, 0.980, 0.988); // #EAFAFC
  static const cardBord  = PdfColor(0.816, 0.929, 0.941); // #D0ECF0
  static const green     = PdfColor(0.180, 0.490, 0.196); // Field Work
  static const blue      = PdfColor(0.082, 0.392, 0.745); // Office Work
  static const purple    = PdfColor(0.416, 0.098, 0.608); // Software
  static const rowAlt    = PdfColor(0.961, 0.988, 0.996);
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

  // Amiri — an Arabic/Latin typeface designed for Naskh-style Arabic typesetting.
  // Served from the Google Fonts CDN; falls back to Helvetica if unavailable.
  static const _amiriUrl =
      'https://fonts.gstatic.com/s/amiri/v27/J7aRnpd8CGxBHqUpvqKo.ttf';
  static const _amiriBoldUrl =
      'https://fonts.gstatic.com/s/amiri/v27/J7acnpd8CGxBHp2VkZY40iM.ttf';

  // ── Font loading ──────────────────────────────────────────────────────────

  /// Attempts to load the Amiri TTF font for Arabic text support.
  /// Falls back to the built-in Helvetica if the network request fails.
  Future<pw.Font> _loadArabicFont({bool bold = false}) async {
    try {
      final resp = await http
          .get(Uri.parse(bold ? _amiriBoldUrl : _amiriUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        return pw.Font.ttf(resp.bodyBytes.buffer.asByteData());
      }
    } catch (_) {
      // Network unavailable or timeout — silent fallback
    }
    return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

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
  }) async {
    // Load fonts concurrently
    final results = await Future.wait([
      _loadArabicFont(bold: false),
      _loadArabicFont(bold: true),
      _loadCustomLogo(student.customLogoUrl),
    ]);
    final baseFont = results[0] as pw.Font;
    final boldFont = results[1] as pw.Font;
    final customLogo = results[2] as pw.MemoryImage?;

    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
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

    // Helper for watermark background
    pw.Widget buildWatermark(pw.Context ctx) {
      if (customLogo == null) return pw.Container();
      return pw.Center(
        child: pw.Opacity(
          opacity: 0.15,
          child: pw.Image(customLogo, width: 300),
        ),
      );
    }

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
          footer: (ctx) => _pageFooter(ctx),
          build:  (ctx) => _buildLogTable(logs, dateFormat),
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
        // ── Gradient top banner ──────────────────────────────────────────
        pw.Container(
          height: 10,
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [_C.cyan, _C.teal]),
          ),
        ),

        // ── White content area ───────────────────────────────────────────
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(56, 52, 56, 36),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // InternLog badge
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: _C.bgLight,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        'InternLog  ·  Professional Log',
                        style: pw.TextStyle(
                          font:     pw.Font.helveticaBold(),
                          fontSize: 9,
                          color:    _C.teal,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (customLogo != null)
                      pw.Container(
                        height: 50,
                        child: pw.Image(customLogo),
                      ),
                  ],
                ),

                pw.SizedBox(height: 52),

                // Main title
                pw.Text(
                  'Internship Training',
                  style: pw.TextStyle(
                    font:      pw.Font.helveticaBold(),
                    fontSize:  36,
                    color:     _C.dark,
                    letterSpacing: -0.5,
                  ),
                ),
                pw.Text(
                  'Daily Activity Report',
                  style: pw.TextStyle(
                    font:      pw.Font.helveticaBold(),
                    fontSize:  36,
                    color:     _C.cyan,
                    letterSpacing: -0.5,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Civil Engineering  ·  Field Training Program',
                  style: pw.TextStyle(
                    font:     pw.Font.helveticaOblique(),
                    fontSize: 13,
                    color:    _C.muted,
                  ),
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
                  '${DateFormat('MMMM d, yyyy — HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    font:     pw.Font.helveticaOblique(),
                    fontSize: 8,
                    color:    _C.muted,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Cyan accent bottom bar ───────────────────────────────────────
        pw.Container(height: 6, color: _C.cyan),
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
    final fieldWork  = logs.where((l) => l.taskType == TaskType.fieldWork).length;
    final officeWork = logs.where((l) => l.taskType == TaskType.officeWork).length;
    final software   = logs.where((l) => l.taskType == TaskType.software).length;

    String fill(String v, [String blank = '________________________________']) =>
        v.isNotEmpty ? v : blank;

    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: _C.cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _C.cardBord, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section label
          pw.Text(
            'STUDENT INFORMATION',
            style: pw.TextStyle(
              font:          pw.Font.helveticaBold(),
              fontSize:      8,
              color:         _C.muted,
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
            '${fmt.format(dateFrom)}   →   ${fmt.format(dateTo)}',
          ),

          pw.SizedBox(height: 18),
          pw.Divider(color: _C.cardBord, thickness: 0.8),
          pw.SizedBox(height: 14),

          // Summary stats
          pw.Row(
            children: [
              _statBox('${logs.length}', 'Total Logs',   _C.cyan),
              pw.SizedBox(width: 10),
              _statBox('$fieldWork',  'Field Work',   _C.green),
              pw.SizedBox(width: 10),
              _statBox('$officeWork', 'Office Work',  _C.blue),
              pw.SizedBox(width: 10),
              _statBox('$software',   'Software',     _C.purple),
            ],
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
                font:     pw.Font.helveticaBold(),
                fontSize: 9.5,
                color:    _C.muted,
              ),
            ),
          ),
          pw.Text(
            ':  ',
            style: pw.TextStyle(
              font:     pw.Font.helvetica(),
              fontSize: 9.5,
              color:    _C.muted,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font:     pw.Font.helveticaBold(),
                fontSize: 9.5,
                color:    _C.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _statBox(String value, String label, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: pw.BoxDecoration(
          color:        PdfColor(accent.red, accent.green, accent.blue, 0.06),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(
            color: PdfColor(accent.red, accent.green, accent.blue, 0.22),
            width: 0.8,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font:     pw.Font.helveticaBold(),
                fontSize: 22,
                color:    accent,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font:     pw.Font.helvetica(),
                fontSize: 7.5,
                color:    _C.muted,
              ),
            ),
          ],
        ),
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
                font:     pw.Font.helveticaBold(),
                fontSize: 14,
                color:    _C.dark,
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
                  font:     pw.Font.helveticaOblique(),
                  fontSize: 9,
                  color:    _C.muted,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, color: _C.cyan),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Container(height: 0.8, color: _C.divider),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by InternLog  ·  Professional Log for Civil Engineering',
              style: pw.TextStyle(
                font:     pw.Font.helveticaOblique(),
                fontSize: 7.5,
                color:    _C.muted,
              ),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(
                font:     pw.Font.helveticaBold(),
                fontSize: 7.5,
                color:    _C.muted,
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
        color: _C.cyan,
        borderRadius: pw.BorderRadius.only(
          topLeft:  pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
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
      final i   = e.key;
      final log = e.value;
      final bg  = i.isEven ? PdfColors.white : _C.rowAlt;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          // Date
          _tdCell(
            fmt.format(log.date),
            isBold: true,
            color: _C.cyan,
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
          // Issues — RTL if Arabic
          _tdCell(
            log.issuesFound.trim().isEmpty ? '—' : log.issuesFound,
            direction: hasArabic(log.issuesFound)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            dimmed: log.issuesFound.trim().isEmpty,
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
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _C.divider, width: 0.5),
          verticalInside:   pw.BorderSide(color: _C.divider, width: 0.5),
          bottom: pw.BorderSide(color: _C.cardBord, width: 0.8),
          left:   pw.BorderSide(color: _C.cardBord, width: 0.8),
          right:  pw.BorderSide(color: _C.cardBord, width: 0.8),
          top:    pw.BorderSide(color: _C.cardBord, width: 0.8),
        ),
        children: [header, ...rows],
      ),
    ];
  }

  pw.Widget _thCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font:          pw.Font.helveticaBold(),
          fontSize:      7.5,
          color:         PdfColors.white,
          letterSpacing: 0.6,
        ),
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
      child: pw.Text(
        text,
        textDirection: direction,
        style: pw.TextStyle(
          font:        isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
          fontSize:    8,
          color:       dimmed ? _C.muted : (color ?? _C.dark),
          lineSpacing: 1.5,
        ),
        maxLines: 6,
        overflow: pw.TextOverflow.clip,
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
                font:     pw.Font.helveticaBold(),
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
}
