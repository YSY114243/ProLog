import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Reports tab providing a summary, date range filtering, and PDF generation.
class ReportsTab extends StatefulWidget {
  final List<DailyLog> allLogs;

  const ReportsTab({super.key, required this.allLogs});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTimeRange? _dateRange;
  bool _isGenerating = false;

  List<DailyLog> get _filteredLogs {
    if (_dateRange == null) {
      final sorted = [...widget.allLogs]..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    }
    return widget.allLogs.where((log) {
      final start = _dateRange!.start;
      final end = _dateRange!.end;
      final logD = DateTime(log.date.year, log.date.month, log.date.day);
      final startD = DateTime(start.year, start.month, start.day);
      final endD = DateTime(end.year, end.month, end.day);
      return logD.compareTo(startD) >= 0 && logD.compareTo(endD) <= 0;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryCyan,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
  }

  Future<void> _download() async {
    final logs = _filteredLogs;
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs available in this date range.')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    
    final uniId = meta?['uni_id']?.toString().trim() ?? '';
    final major = meta?['major']?.toString().trim() ?? '';
    final uniName = meta?['uni_name']?.toString().trim() ?? '';
    final company = meta?['company']?.toString().trim() ?? '';
    final supervisor = meta?['supervisor']?.toString().trim() ?? '';
    final fullName = meta?['full_name']?.toString().trim() ?? '';
    final customLogoUrl = meta?['custom_logo_url']?.toString().trim();

    if (uniId.isEmpty || major.isEmpty || uniName.isEmpty || company.isEmpty || supervisor.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profile Incomplete', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Please fill your Academic Profile in Settings before generating the report.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final student = StudentInfo(
      name: fullName.isNotEmpty ? fullName : 'Student',
      universityId: uniId,
      major: major,
      universityName: uniName,
      company: company,
      supervisor: supervisor,
      customLogoUrl: customLogoUrl,
    );

    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      final bytes = await PdfService.instance.generateInternshipReport(
        logs: logs,
        student: student,
      );
      await PdfService.instance.downloadPdf(bytes, 'Internship_Report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    final total = logs.length;
    final field = logs.where((l) => l.taskType == TaskType.fieldWork).length;
    final office = logs.where((l) => l.taskType == TaskType.officeWork).length;
    final software = logs.where((l) => l.taskType == TaskType.software).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              const Text(
                'Generate Final Report',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure the date range to include in your final internship PDF report. '
                'The report will include a formatted cover page and a structured table of your activities.',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              // ── Date Range Filter ────────────────────────────────
              const Text(
                'DATE FILTER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _dateRange != null ? AppTheme.cyanLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _dateRange != null ? AppTheme.primaryCyan.withValues(alpha: 0.4) : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range_rounded, 
                              color: _dateRange != null ? AppTheme.primaryCyan : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _dateRange != null
                                    ? '${DateFormat('MMM d, yyyy').format(_dateRange!.start)}  —  ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}'
                                    : 'All time (tap to filter dates)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _dateRange != null ? FontWeight.w600 : FontWeight.w400,
                                  color: _dateRange != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _clearDateRange,
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Clear filter',
                      color: AppTheme.textMuted,
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 40),

              // ── Summary Card ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.cyanLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryCyan),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Report Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _StatBadge('$total', 'Total Logs', AppTheme.textPrimary, AppTheme.divider.withValues(alpha: 0.3)),
                        const SizedBox(width: 16),
                        _StatBadge('$field', 'Field', TaskType.fieldWork.color, TaskType.fieldWork.bgColor),
                        const SizedBox(width: 16),
                        _StatBadge('$office', 'Office', TaskType.officeWork.color, TaskType.officeWork.bgColor),
                        const SizedBox(width: 16),
                        _StatBadge('$software', 'Software', TaskType.software.color, TaskType.software.bgColor),
                      ],
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating || total == 0 ? null : _download,
                        icon: _isGenerating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.download_rounded, size: 22),
                        label: Text(
                          _isGenerating ? 'Generating PDF...' : 'Download PDF Report',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatBadge(this.value, this.label, this.textColor, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
