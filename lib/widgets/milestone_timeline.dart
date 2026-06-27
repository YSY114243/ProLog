import 'package:flutter/material.dart';

class MilestoneTask {
  final String title;
  final String formId;
  final int requiredWeek;
  final bool isCompleted;
  final VoidCallback? onTap;
  final String? customStatusText;
  final bool isReadOnly;

  MilestoneTask({
    required this.title,
    required this.formId,
    required this.requiredWeek,
    required this.isCompleted,
    this.onTap,
    this.customStatusText,
    this.isReadOnly = false,
  });
}

class MilestoneTimeline extends StatelessWidget {
  final DateTime? trainingStartDate;
  final List<MilestoneTask> tasks;
  final bool isSupervisorView;
  final VoidCallback? onSetStartDate;

  const MilestoneTimeline({
    super.key,
    required this.trainingStartDate,
    required this.tasks,
    this.isSupervisorView = false,
    this.onSetStartDate,
  });

  int get currentWeek {
    if (trainingStartDate == null) return 0;
    final diffDays = DateTime.now().difference(trainingStartDate!).inDays;
    return diffDays < 0 ? 0 : (diffDays ~/ 7) + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (trainingStartDate == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: InkWell(
          onTap: onSetStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Training Start Date not set. Tap here to set it and unlock the timeline.',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                if (onSetStartDate != null)
                  const Icon(Icons.chevron_right, color: Colors.orange),
              ],
            ),
          ),
        ),
      );
    }

    final sortedTasks = List<MilestoneTask>.from(tasks)..sort((a, b) => a.requiredWeek.compareTo(b.requiredWeek));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Week $currentWeek',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sortedTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == sortedTasks.length - 1;

          return _buildTimelineItem(context, task, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, MilestoneTask task, bool isLast) {
    final bool isLocked = currentWeek < task.requiredWeek && !task.isCompleted;
    final bool isActive = currentWeek >= task.requiredWeek && !task.isCompleted;
    
    Color statusColor;
    IconData statusIcon;
    
    if (task.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isActive) {
      statusColor = task.isReadOnly ? Colors.orange : Theme.of(context).colorScheme.primary;
      statusIcon = task.isReadOnly ? Icons.hourglass_empty : Icons.radio_button_unchecked;
    } else {
      statusColor = Colors.grey.shade400;
      statusIcon = Icons.lock;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: statusColor.withAlpha(100),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 8),
              child: Card(
                elevation: isActive ? 2 : 0,
                color: isLocked ? Colors.grey.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? statusColor.withAlpha(100) : Colors.grey.shade200,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: (isLocked || task.isReadOnly) ? null : task.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Week ${task.requiredWeek}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.formId,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                            color: isLocked ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (task.isCompleted) ...[
                              const Icon(Icons.done_all, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(task.customStatusText ?? 'Submitted to Supabase', style: const TextStyle(color: Colors.green, fontSize: 12)),
                            ] else if (isLocked) ...[
                              const Icon(Icons.lock_clock, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Unlocks in Week ${task.requiredWeek}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ] else ...[
                              Icon(task.isReadOnly ? Icons.hourglass_bottom : Icons.touch_app, size: 16, color: task.isReadOnly ? Colors.orange : Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(task.customStatusText ?? (isSupervisorView ? 'Tap to Submit' : 'Tap to Fill Form'), 
                                style: TextStyle(color: task.isReadOnly ? Colors.orange : Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
