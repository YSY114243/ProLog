import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'intern_log_logo.dart';

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
    _FaDestination(
      icon: FontAwesomeIcons.gaugeHigh,
      label: 'Dashboard',
    ),
    _FaDestination(
      icon: FontAwesomeIcons.bookOpen,
      label: 'My Logs',
    ),
    _FaDestination(
      icon: FontAwesomeIcons.chartLine,
      label: 'Reports',
    ),
    _FaDestination(
      icon: FontAwesomeIcons.shield,
      label: 'Challenges & Learnings',
    ),
    _FaDestination(
      icon: FontAwesomeIcons.fileContract,
      label: 'Digital Forms',
    ),
    _FaDestination(
      icon: FontAwesomeIcons.gear,
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
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // ── Logo header ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
            ),
            child: const InternLogLogo.small(),
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
                  icon: FaIcon(dest.icon, size: 16),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.userMetadata?['major']?.toString().isNotEmpty == true
                            ? user!.userMetadata!['major'].toString()
                            : 'Engineering',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
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

/// Simple data holder for a sidebar destination using FA icons.
class _FaDestination {
  final dynamic icon;
  final String label;
  const _FaDestination({required this.icon, required this.label});
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
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
        : _hovered
            ? const Color(0xFFF0FAFB)
            : Colors.transparent;
    final fgColor =
        widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), width: 1)
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
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