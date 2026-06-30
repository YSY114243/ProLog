import 'package:flutter/material.dart';
import '../models/daily_log.dart';
import '../widgets/log_card.dart';

class MyLogsTab extends StatelessWidget {
  final List<DailyLog> logs;
  final bool isDesktop;
  final bool isMobile;
  final TextEditingController searchCtrl;
  final String filterType;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;
  final ValueChanged<DailyLog>? onEdit;
  final ValueChanged<DailyLog>? onDelete;

  const MyLogsTab({
    super.key,
    required this.logs,
    required this.isDesktop,
    required this.isMobile,
    required this.searchCtrl,
    required this.filterType,
    required this.onSearch,
    required this.onFilter,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = isDesktop ? 32.0 : 16.0;

    final total = logs.length;
    final field = logs.where((l) => l.taskType == TaskType.fieldWork).length;
    final office = logs.where((l) => l.taskType == TaskType.officeWork).length;
    final software = logs.where((l) => l.taskType == TaskType.software).length;

    return CustomScrollView(
      slivers: [
        // ── Report Summary ───────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
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
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Report Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _StatBadge('$total', 'Total Logs', Theme.of(context).colorScheme.onSurface, Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      const SizedBox(width: 16),
                      _StatBadge('$field', 'Field', TaskType.fieldWork.color, TaskType.fieldWork.bgColor),
                      const SizedBox(width: 16),
                      _StatBadge('$office', 'Office', TaskType.officeWork.color, TaskType.officeWork.bgColor),
                      const SizedBox(width: 16),
                      _StatBadge('$software', 'Software', TaskType.software.color, TaskType.software.bgColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Search + filter bar ──────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 16),
          sliver: SliverToBoxAdapter(
            child: _SearchFilterBar(
              controller: searchCtrl,
              filterType: filterType,
              onSearch: onSearch,
              onFilter: onFilter,
            ),
          ),
        ),

        // ── Section header ───────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text('All Logs', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('${logs.length} entries', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),

        // ── Log cards ────────────────────────────────────────────────────
        logs.isEmpty
            ? SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 40, hPad, 40),
                sliver: const SliverToBoxAdapter(child: _EmptyState()),
              )
            : isDesktop
                ? SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => LogCard(
                          log: logs[i],
                          onEdit: () => onEdit?.call(logs[i]),
                          onDelete: () => onDelete?.call(logs[i]),
                        ),
                        childCount: logs.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.05,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LogCard(
                            log: logs[i],
                            onEdit: () => onEdit?.call(logs[i]),
                            onDelete: () => onDelete?.call(logs[i]),
                          ),
                        ),
                        childCount: logs.length,
                      ),
                    ),
                  ),
      ],
    );
  }
}

// ── Search + Filter bar ───────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String filterType;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;

  const _SearchFilterBar({
    required this.controller,
    required this.filterType,
    required this.onSearch,
    required this.onFilter,
  });

  static const _filters = [
    'All',
    'Field Work',
    'Office Work',
    'Software',
    'With Challenges',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search field ───────────────────────────────────────────────
        TextField(
          controller: controller,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search by description, issues, or task type…',
            hintStyle: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0ECF0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Filter chips ───────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f,
                      selected: filterType == f,
                      onTap: () => onFilter(f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFFD0ECF0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Theme.of(context).colorScheme.surface : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: const Border.fromBorderSide(BorderSide(color: Color(0xFFD0ECF0))),
          ),
          child: Icon(Icons.search_off_rounded, size: 36, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(
          'No logs found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          'Try adjusting your search or task type filter.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8))),
            ),
          ],
        ),
      ),
    );
  }
}