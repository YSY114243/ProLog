import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Responsive sidebar navigation for desktop / rail for tablet / bottom bar for mobile.
class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.book_outlined),
      selectedIcon: Icon(Icons.book_rounded),
      label: 'My Logs',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics_rounded),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final email = user?.email ?? '';
    final displayName = (fullName != null && fullName.isNotEmpty) ? fullName : (email.isNotEmpty ? email : 'User');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          // ── Logo header ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryCyan, AppTheme.accentTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ProLog',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Professional Log',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Nav items ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _destinations.length,
              itemBuilder: (context, i) {
                final dest = _destinations[i];
                final selected = i == selectedIndex;
                return _SidebarItem(
                  icon: selected
                      ? (dest.selectedIcon ?? dest.icon)
                      : dest.icon,
                  label: dest.label,
                  selected: selected,
                  onTap: () => onDestinationSelected(i),
                );
              },
            ),
          ),

          // ── Bottom user profile ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cyanLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryCyan,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Civil Engineering',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppTheme.primaryCyan.withValues(alpha: 0.1)
        : _hovered
            ? const Color(0xFFF0FAFB)
            : Colors.transparent;
    final fgColor =
        widget.selected ? AppTheme.primaryCyan : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.selected
                ? Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.2), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(color: fgColor, size: 20),
                child: widget.icon,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: fgColor,
                ),
              ),
              if (widget.selected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryCyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
