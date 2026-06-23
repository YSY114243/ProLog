import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../services/supabase_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/intern_log_logo.dart';
import '../services/pdf_service.dart';
import 'add_log_screen.dart';
import 'reports_tab.dart';
import 'settings_tab.dart';
import 'my_logs_tab.dart';
import 'dashboard_overview_tab.dart';

/// Breakpoints for responsive layout.
class _Bp {
  static const double mobile = 600;
  static const double tablet = 960;
}

/// Main dashboard screen – responsive for mobile, tablet, and desktop.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int    _navIndex    = 0;
  String _searchQuery = '';
  String _filterType  = 'All'; // 'All' | TaskType.label values
  final  TextEditingController _searchCtrl = TextEditingController();

  // Starts empty; populated from Supabase.
  List<DailyLog> _logs = [];

  // ── Derived data ──────────────────────────────────────────────────────────

  List<DailyLog> get _filteredLogs {
    return _logs.where((log) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          log.description.toLowerCase().contains(q) ||
          log.issuesFound.toLowerCase().contains(q) ||
          log.taskType.label.toLowerCase().contains(q);
      final matchesType =
          _filterType == 'All' || log.taskType.label == _filterType;
      return matchesSearch && matchesType;
    }).toList();
  }

  int _countByType(TaskType t) => _logs.where((l) => l.taskType == t).length;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    try {
      final remote = await SupabaseService.instance.fetchLogs();
      if (mounted) {
        setState(() => _logs = remote);
      }
    } catch (_) {
      // Keep empty list — user not signed in or network error.
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openAddLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLogScreen(
          onSaved: (log) {
            setState(() => _logs.insert(0, log));
          },
        ),
      ),
    );
  }

  void _editLog(DailyLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLogScreen(
          initialLog: log,
          onSaved: (updated) {
            setState(() {
              final idx = _logs.indexWhere((l) => l.id == updated.id);
              if (idx != -1) {
                _logs[idx] = updated;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _deleteLog(DailyLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Log',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to delete this log? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Only call Supabase delete for real UUID IDs (not placeholders)
      if (log.id.isNotEmpty && !log.id.startsWith('placeholder')) {
        await SupabaseService.instance.deleteLog(log.id);
      }
      if (mounted) {
        setState(() => _logs.removeWhere((l) => l.id == log.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Log deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _downloadReport() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs available to generate report.')),
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
              child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF report...')),
    );

    try {
      final bytes = await PdfService.instance.generateInternshipReport(
        logs: _logs,
        student: student,
      );
      await PdfService.instance.downloadPdf(bytes, 'Internship_Report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width >= _Bp.tablet;
    final isMobile  = width < _Bp.mobile;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // ── Bottom nav (mobile only) ──────────────────────────────────────────
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              destinations: [
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.gaugeHigh, size: 18),
                  selectedIcon: FaIcon(FontAwesomeIcons.gaugeHigh,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.bookOpen, size: 18),
                  selectedIcon: FaIcon(FontAwesomeIcons.bookOpen,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  label: 'My Logs',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.chartLine, size: 18),
                  selectedIcon: FaIcon(FontAwesomeIcons.chartLine,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.gear, size: 18),
                  selectedIcon: FaIcon(FontAwesomeIcons.gear,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  label: 'Settings',
                ),
              ],
            )
          : null,

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLog,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
        label: const Text(
          'New Daily Log',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      body: Row(
        children: [
          // ── Sidebar (desktop) ───────────────────────────────────────────
          if (isDesktop)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
              ),
              child: AppSidebar(
                selectedIndex: _navIndex,
                onDestinationSelected: (i) =>
                    setState(() => _navIndex = i),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _AppHeader(
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  title: _navIndex == 0 ? 'Dashboard' :
                         _navIndex == 1 ? 'My Logs' :
                         _navIndex == 2 ? 'Reports' : 'Settings',
                  onDownload: _downloadReport,
                ),
                Expanded(
                  child: _navIndex == 0
                      ? DashboardOverviewTab(
                          allLogs: _logs,
                          fieldWorkCount: _countByType(TaskType.fieldWork),
                          officeWorkCount: _countByType(TaskType.officeWork),
                          softwareCount: _countByType(TaskType.software),
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                          onAddLog: _openAddLog,
                          onEdit: _editLog,
                          onDelete: _deleteLog,
                        )
                      : _navIndex == 1
                          ? MyLogsTab(
                              logs: _filteredLogs,
                              isDesktop: isDesktop,
                              isMobile: isMobile,
                              searchCtrl: _searchCtrl,
                              filterType: _filterType,
                              onSearch: (q) => setState(() => _searchQuery = q),
                              onFilter: (f) => setState(() => _filterType = f),
                              onEdit: _editLog,
                              onDelete: _deleteLog,
                            )
                      : _navIndex == 2
                          ? ReportsTab(allLogs: _logs)
                          : const SettingsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Header ────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isMobile;
  final String title;
  final VoidCallback onDownload;

  const _AppHeader({
    required this.isDesktop,
    required this.isMobile,
    required this.title,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16, vertical: 16),
      child: Row(
        children: [
          if (!isDesktop) ...[
            const InternLogLogo.small(),
            const Spacer(),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(
                  DateFormat('EEEE, MMMM d yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Spacer(),
          ],

          // Download Report Button
          OutlinedButton.icon(
            onPressed: onDownload,
            icon: const FaIcon(FontAwesomeIcons.filePdf, size: 15),
            label: const Text('Download Report', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: const BorderSide(color: Color(0xFFD0ECF0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}