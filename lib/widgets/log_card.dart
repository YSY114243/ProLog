import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';

/// A richly-styled card that displays a single [DailyLog] entry.
class LogCard extends StatefulWidget {
  final DailyLog log;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LogCard({
    super.key,
    required this.log,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFDFF6F9) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                  : const Color(0xFFD0ECF0),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Date chip + Task type badge + menu ─────────────
                Row(
                  children: [
                    _DateChip(date: log.date),
                    const Spacer(),
                    _TaskTypeBadge(taskType: log.taskType),
                    const SizedBox(width: 4),
                    _CardMenu(
                      onEdit:   widget.onEdit,
                      onDelete: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Row 2: Description ────────────────────────────────────
                Text(
                  log.description,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ── Row 3: Issues & Solutions ─────────────────────────────
                if (log.issuesFound.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFFFFECB3), width: 1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFF57C00)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            log.issuesFound,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF5D4037),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Divider ───────────────────────────────────────────────
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ── Row 4: Footer — image indicator + date formatted ──────
                Row(
                  children: [
                    Icon(
                      log.taskType.icon,
                      size: 14,
                      color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      log.taskType.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    if (log.imageUrl != null) ...[
                      Icon(Icons.image_outlined,
                          size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Photo attached',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      DateFormat('EEE, MMM d').format(log.date),
                      style: textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTypeBadge extends StatelessWidget {
  final TaskType taskType;
  const _TaskTypeBadge({required this.taskType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: taskType.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(taskType.icon, size: 12, color: taskType.color),
          const SizedBox(width: 4),
          Text(
            taskType.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: taskType.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card popup menu (⋮) ───────────────────────────────────────────────────────

class _CardMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CardMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
      padding: EdgeInsets.zero,
      tooltip: 'Options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      onSelected: (action) {
        switch (action) {
          case _MenuAction.edit:
            onEdit?.call();
          case _MenuAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 10),
              Text('Edit',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.delete,
          child: Row(
            children: const [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Delete',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MenuAction { edit, delete }