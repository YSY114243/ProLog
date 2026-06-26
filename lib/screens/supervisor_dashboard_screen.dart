import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final _dateFormat = DateFormat('EEE, d MMM yyyy');

  List<DailyLog> _pendingLogs = [];
  List<Map<String, dynamic>> _trainees = [];
  bool _loadingLogs = true;
  bool _loadingTrainees = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadPendingLogs();
    _loadTrainees();
  }

  Future<void> _loadPendingLogs() async {
    setState(() => _loadingLogs = true);
    final logs = await SupabaseService.instance.getPendingLogsForSupervisor();
    if (mounted) {
      setState(() {
        _pendingLogs = logs;
        _loadingLogs = false;
      });
    }
  }

  Future<void> _loadTrainees() async {
    setState(() => _loadingTrainees = true);
    final trainees = await SupabaseService.instance.getTraineesForSupervisor();
    if (mounted) {
      setState(() {
        _trainees = trainees;
        _loadingTrainees = false;
      });
    }
  }

  Future<void> _handleApproval(String logId, String status) async {
    // Optimistic UI update
    setState(() {
      _pendingLogs.removeWhere((log) => log.id == logId);
    });

    try {
      await SupabaseService.instance.updateLogApprovalStatus(logId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Log $status successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      _loadPendingLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating log. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervisor Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Log Out',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pending Approvals'),
              Tab(icon: Icon(Icons.people), text: 'My Trainees'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingLogsTab(),
            _buildTraineesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingLogsTab() {
    if (_loadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingLogs.length,
      itemBuilder: (context, index) {
        final log = _pendingLogs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateFormat.format(log.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Chip(
                      label: Text(log.taskType.label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: log.taskType.bgColor,
                      labelStyle: TextStyle(color: log.taskType.color),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(log.description),
                if (log.issuesFound.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Issues & Solutions:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(log.issuesFound),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _handleApproval(log.id, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _handleApproval(log.id, 'approved'),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTraineesTab() {
    if (_loadingTrainees) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trainees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No trainees assigned yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trainees.length,
      itemBuilder: (context, index) {
        final trainee = _trainees[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(trainee['full_name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${trainee['major'] ?? 'Unknown Major'} • ${trainee['uni_name'] ?? 'Unknown University'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Could open a screen to view this specific student's log history
            },
          ),
        );
      },
    );
  }
}
