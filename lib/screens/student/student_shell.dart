import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common.dart';

/// Bottom-nav scaffold for the student side (Home / Practice / Exams /
/// Profile), per the student hub mockups.
class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.title,
    required this.body,
    this.currentTab,
    this.actions,
    this.leading,
    this.showNav = true,
  });

  final String title;
  final Widget body;
  final int? currentTab; // 0 home, 1 practice, 2 exams, 3 profile
  final List<Widget>? actions;
  final Widget? leading;
  final bool showNav;

  static const _tabs = <(String, IconData, String)>[
    ('Home', Icons.home_outlined, '/student/hub'),
    ('Practice', Icons.psychology_outlined, '/student/practice-generator'),
    ('Exams', Icons.assignment_outlined, '/student/exams'),
    ('Profile', Icons.person_outline, '/student/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      // Home tab is the student root; other tabs fall back to it.
      fallbackRoute: currentTab == 0 ? null : '/student/hub',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: leading ??
              (Navigator.of(context).canPop()
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop())
                  : null),
          automaticallyImplyLeading: false,
          titleSpacing:
              (leading == null && !Navigator.of(context).canPop()) ? 16 : 0,
          title: Row(children: [
            if (leading == null) ...[
              const BrandMark(size: 26),
              const SizedBox(width: 8),
            ],
            Text(title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
          actions: [
            ...?actions,
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications?role=student'),
              icon: const Icon(Icons.notifications_none, size: 21),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: InitialsAvatar(api.displayName ?? 'Student',
                  size: 32, color: AppColors.teal),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: body,
          ),
        ),
        bottomNavigationBar: showNav
            ? Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 62,
                    child: Row(children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(child: _NavItem(tab: _tabs[i], selected: currentTab == i)),
                    ]),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected});
  final (String, IconData, String) tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final (label, icon, route) = tab;
    final color = selected ? AppColors.teal : AppColors.muted;
    return InkWell(
      onTap: () => context.go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(label, style: AppTheme.mono(9, FontWeight.w600, color: color, ls: 0.5)),
        ],
      ),
    );
  }
}

/// Section header used across student screens (icon + label).
class StudentSection extends StatelessWidget {
  const StudentSection(this.title, {super.key, this.icon, this.trailing});
  final String title;
  final IconData? icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.teal),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ]),
      );
}
