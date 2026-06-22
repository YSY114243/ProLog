import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../widgets/log_card.dart';
import '../widgets/stat_card.dart';
import 'paywall_screen.dart';

class DashboardOverviewTab extends StatelessWidget {
  final List<DailyLog> allLogs;
  final int fieldWorkCount;
  final int officeWorkCount;
  final int softwareCount;
  final bool isMobile;
  final bool isDesktop;
  final VoidCallback onAddLog;
  final ValueChanged<DailyLog>? onEdit;
  final ValueChanged<DailyLog>? onDelete;

  const DashboardOverviewTab({
    super.key,
    required this.allLogs,
    required this.fieldWorkCount,
    required this.officeWorkCount,
    required this.softwareCount,
    required this.isMobile,
    required this.isDesktop,
    required this.onAddLog,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = isDesktop ? 32.0 : 16.0;

    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final firstName = (fullName != null && fullName.isNotEmpty) ? fullName.split(' ').first : 'User';
    final isPremium = user?.userMetadata?['is_premium'] == true;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Message ──────────────────────────────────────────────
          Text(
            'Welcome back, $firstName 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is a quick overview of your internship progress.',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // ── Summary Row ──────────────────────────────────────────────────
          _StatsRow(
            totalLogs: allLogs.length,
            fieldWorkCount: fieldWorkCount,
            officeWorkCount: officeWorkCount,
            softwareCount: softwareCount,
            isMobile: isMobile,
          ),
          const SizedBox(height: 40),

          // ── Task Distribution Chart ──────────────────────────────────────
          if (allLogs.isNotEmpty) ...[
            _TaskDistributionChart(
              fieldWorkCount: fieldWorkCount,
              officeWorkCount: officeWorkCount,
              softwareCount: softwareCount,
            ),
            const SizedBox(height: 40),
          ],

          // ── Premium Upgrade Card ─────────────────────────────────────────
          if (!isPremium) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.crown, size: 28, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock custom university logos on PDF reports and AI-powered polishing.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 16),
                  if (!isMobile)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaywallScreen(isVoluntary: true)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],

          // ── Recent Activity ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Showing last 3',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allLogs.isEmpty)
            Text(
              'No logs added yet. Tap the button above to get started!',
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allLogs.length > 3 ? 3 : allLogs.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LogCard(
                    log: allLogs[i],
                    onEdit: () => onEdit?.call(allLogs[i]),
                    onDelete: () => onDelete?.call(allLogs[i]),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalLogs;
  final int fieldWorkCount;
  final int officeWorkCount;
  final int softwareCount;
  final bool isMobile;

  const _StatsRow({
    required this.totalLogs,
    required this.fieldWorkCount,
    required this.officeWorkCount,
    required this.softwareCount,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      (FontAwesomeIcons.clipboardList, 'Total Logs',   '$totalLogs',      Theme.of(context).colorScheme.primary),
      (FontAwesomeIcons.helmetSafety, 'Field Work',   '$fieldWorkCount',  TaskType.fieldWork.color),
      (FontAwesomeIcons.buildingColumns,'Office Work', '$officeWorkCount', TaskType.officeWork.color),
      (FontAwesomeIcons.laptopCode,   'Software',     '$softwareCount',   TaskType.software.color),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => StatCard(
          icon: stats[i].$1,
          label: stats[i].$2,
          value: stats[i].$3,
          accentColor: stats[i].$4,
        ),
      );
    }

    return Row(
      children: stats
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 14 : 0),
                child: StatCard(
                  icon: e.value.$1,
                  label: e.value.$2,
                  value: e.value.$3,
                  accentColor: e.value.$4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Task Distribution Chart ───────────────────────────────────────────────────

class _TaskDistributionChart extends StatefulWidget {
  final int fieldWorkCount;
  final int officeWorkCount;
  final int softwareCount;

  const _TaskDistributionChart({
    required this.fieldWorkCount,
    required this.officeWorkCount,
    required this.softwareCount,
  });

  @override
  State<_TaskDistributionChart> createState() => _TaskDistributionChartState();
}

class _TaskDistributionChartState extends State<_TaskDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: _showingSections(),
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Indicator(
                    color: TaskType.fieldWork.color,
                    text: 'Field Work',
                    isSquare: false,
                  ),
                  const SizedBox(height: 12),
                  _Indicator(
                    color: TaskType.officeWork.color,
                    text: 'Office Work',
                    isSquare: false,
                  ),
                  const SizedBox(height: 12),
                  _Indicator(
                    color: TaskType.software.color,
                    text: 'Software',
                    isSquare: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return [
      _buildSection(
        index: 0,
        value: widget.fieldWorkCount.toDouble(),
        title: '${widget.fieldWorkCount}',
        color: TaskType.fieldWork.color,
      ),
      _buildSection(
        index: 1,
        value: widget.officeWorkCount.toDouble(),
        title: '${widget.officeWorkCount}',
        color: TaskType.officeWork.color,
      ),
      _buildSection(
        index: 2,
        value: widget.softwareCount.toDouble(),
        title: '${widget.softwareCount}',
        color: TaskType.software.color,
      ),
    ];
  }

  PieChartSectionData _buildSection({
    required int index,
    required double value,
    required String title,
    required Color color,
  }) {
    final isTouched = index == touchedIndex;
    final fontSize = isTouched ? 20.0 : 14.0;
    final radius = isTouched ? 60.0 : 50.0;

    return PieChartSectionData(
      color: color,
      value: value > 0 ? value : 0.1, // So empty sections don't crash the chart visually
      title: value > 0 ? title : '',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.color,
    required this.text,
    required this.isSquare,
  });

  final Color color;
  final String text;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        )
      ],
    );
  }
}