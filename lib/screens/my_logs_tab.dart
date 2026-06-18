import 'package:flutter/material.dart';
import '../models/daily_log.dart';
import '../theme/app_theme.dart';
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

    return CustomScrollView(
      slivers: [
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
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.cyanLight,
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
              borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
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
          color: selected ? AppTheme.primaryCyan : AppTheme.cyanLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryCyan : const Color(0xFFD0ECF0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
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
            color: AppTheme.cyanCardBg,
            borderRadius: BorderRadius.circular(20),
            border: const Border.fromBorderSide(BorderSide(color: Color(0xFFD0ECF0))),
          ),
          child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        const Text(
          'No logs found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Try adjusting your search or task type filter.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
