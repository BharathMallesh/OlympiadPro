import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../data/api.dart';
import 'common.dart';

class NavDest {
  const NavDest(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const kNavDestinations = <NavDest>[
  NavDest('Dashboard', Icons.dashboard_outlined, '/dashboard'),
  NavDest('Question Bank', Icons.menu_book_outlined, '/bank'),
  NavDest('My Classes', Icons.groups_outlined, '/analytics/class'),
  NavDest('Exam Creator', Icons.edit_note_outlined, '/wizard/details'),
  NavDest('Live Proctoring', Icons.sensors_outlined, '/live/console'),
  NavDest('Grading', Icons.star_outline, '/grading/submissions'),
  NavDest('Analytics', Icons.bar_chart_outlined, '/analytics/exam'),
];

/// The persistent shell (brand sidebar on wide, drawer on narrow) wrapping
/// dashboard/console/analytics screens.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.currentRoute,
    this.actions,
    this.brand = 'OlympiadPro',
    this.titleWidget,
    this.bottomBar,
  });

  final String title;
  final Widget body;
  final String? currentRoute;
  final List<Widget>? actions;
  final String brand;
  final Widget? titleWidget;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: currentRoute == '/dashboard' ? null : '/dashboard',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      drawer: wide ? null : Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(child: _Sidebar(currentRoute: currentRoute, brand: brand)),
      ),
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop())
                  : null,
              title: titleWidget ?? Text(title,
                  style: Theme.of(context).textTheme.titleLarge),
              actions: actions,
            ),
      bottomNavigationBar: bottomBar,
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 248,
              child: Material(
                color: AppColors.surface,
                child: _Sidebar(currentRoute: currentRoute, brand: brand),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (wide) _TopBar(title: title, titleWidget: titleWidget, actions: actions),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.titleWidget, this.actions});
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(children: [
        Expanded(
          child: titleWidget ??
              Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ...?actions,
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({this.currentRoute, required this.brand});
  final String? currentRoute;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(children: [
              const Icon(Icons.school_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Text(brand,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          // Profile chip
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(children: [
              InitialsAvatar(api.displayName ?? 'Educator', size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(api.displayName ?? 'Educator',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(api.displaySubtitle ?? 'Educator',
                      style: AppTheme.mono(10, FontWeight.w500, ls: 0.5),
                      overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final d in kNavDestinations)
                  _NavTile(dest: d, selected: currentRoute == d.route),
              ],
            ),
          ),
          const Divider(height: 1),
          _NavTile(
            dest: const NavDest('Settings', Icons.settings_outlined, '/settings'),
            selected: currentRoute == '/settings',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.dest, required this.selected});
  final NavDest dest;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? AppColors.primaryStrong.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
              Navigator.of(context).pop();
            }
            context.go(dest.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(dest.icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(dest.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Round top-bar action icon button.
class TopAction extends StatelessWidget {
  const TopAction(this.icon, {super.key, this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
    );
  }
}
