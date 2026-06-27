import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../services/supabase_service.dart';
import '../widgets/milestone_timeline.dart';
import 'auth_screen.dart';
import 'supervisor_evaluation_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final _dateFormat = DateFormat('EEE, d MMM yyyy');

  List<DailyLog> _pendingLogs = [];
  List<Map<String, dynamic>> _trainees = [];
  List<String> _evaluatedStudentIds = [];
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
    final evaluatedIds = await SupabaseService.instance.getEvaluatedStudentIds();
    if (mounted) {
      setState(() {
        _trainees = trainees;
        _evaluatedStudentIds = evaluatedIds;
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
    setState(() {
      _pendingLogs.clear();
      _trainees.clear();
      _evaluatedStudentIds.clear();
      _loadingLogs = true;
      _loadingTrainees = true;
    });
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _showLinkStudentDialog() async {
    final ctrl = TextEditingController();
    bool isLinking = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Link Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the 6-character invite code provided by your student.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    enabled: !isLinking,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLinking ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLinking
                      ? null
                      : () async {
                          final code = ctrl.text.trim().toUpperCase();
                          if (code.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code must be 6 characters.')),
                            );
                            return;
                          }

                          setStateDialog(() => isLinking = true);

                          try {
                            final success = await SupabaseService.instance.linkStudent(code);
                            if (success) {
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Student linked successfully!'), backgroundColor: Colors.green),
                                );
                                _loadData();
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid Code or Student already linked.'), backgroundColor: Colors.red),
                                );
                                setStateDialog(() => isLinking = false);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                              setStateDialog(() => isLinking = false);
                            }
                          }
                        },
                  child: isLinking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Link'),
                ),
              ],
            );
          },
        );
      },
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
        final studentName = _trainees.firstWhere((t) => t['id'] == log.userId, orElse: () => {'full_name': 'Unknown Student'})['full_name'];
        
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
                  children: [
                    Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLinkStudentDialog,
                icon: const Icon(Icons.add_link),
                label: const Text('Link New Student'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ),
          Expanded(
            child: Center(
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
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showLinkStudentDialog,
              icon: const Icon(Icons.add_link),
              label: const Text('Link New Student'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trainees.length,
      itemBuilder: (context, index) {
        final trainee = _trainees[index];
        final studentId = trainee['id'] as String;
        final studentName = trainee['full_name'] ?? 'Unknown Student';
        final isEvaluated = _evaluatedStudentIds.contains(studentId);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${trainee['major'] ?? 'Unknown Major'} • ${trainee['uni_name'] ?? 'Unknown University'}'),
            trailing: FilledButton.icon(
              onPressed: isEvaluated
                  ? null
                  : () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SupervisorEvaluationScreen(
                            studentId: studentId,
                            studentName: studentName,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadTrainees(); // Refresh the list
                      }
                    },
              icon: Icon(isEvaluated ? Icons.check : Icons.assignment_turned_in, size: 18),
              label: Text(isEvaluated ? 'Evaluated' : 'Evaluate'),
              style: FilledButton.styleFrom(
                backgroundColor: isEvaluated ? Colors.grey : Colors.blue.shade700,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
              ),
            ),
            onTap: () {
              _showSupervisorTimeline(context, trainee, isEvaluated);
            },
          ),
        );
      },
    ),
    ),
    ],
    );
  }

  void _showSupervisorTimeline(BuildContext context, Map<String, dynamic> trainee, bool isEvaluated) {
    final studentId = trainee['id'] as String;
    final studentName = trainee['full_name'] ?? 'Unknown Student';
    DateTime? startDate;
    if (trainee['training_start_date'] != null) {
      startDate = DateTime.tryParse(trainee['training_start_date'].toString());
    }
    
    final List<String> submittedForms = trainee['submitted_forms'] != null 
        ? List<String>.from(trainee['submitted_forms']) 
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Timeline for $studentName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              MilestoneTimeline(
                trainingStartDate: startDate,
                isSupervisorView: true,
                tasks: [
                  MilestoneTask(
                    title: 'Submit Training Plan',
                    formId: 'TA-FORM 01',
                    requiredWeek: 1,
                    isCompleted: submittedForms.contains('TA-FORM 01'),
                    onTap: () {
                      // Handle TA-FORM 01
                    },
                  ),
                  MilestoneTask(
                    title: 'Confidential Student Evaluation',
                    formId: 'TA-FORM 03',
                    requiredWeek: 8,
                    isCompleted: isEvaluated || submittedForms.contains('TA-FORM 03'),
                    onTap: () async {
                      if (!isEvaluated) {
                        Navigator.pop(context);
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupervisorEvaluationScreen(
                              studentId: studentId,
                              studentName: studentName,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadTrainees();
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
