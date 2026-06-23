import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'wizard_shell.dart';

class TargetAudienceScreen extends StatefulWidget {
  const TargetAudienceScreen({super.key});
  @override
  State<TargetAudienceScreen> createState() => _TargetAudienceScreenState();
}

class _TargetAudienceScreenState extends State<TargetAudienceScreen> {
  List<dynamic> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await Repo.classes();
      // Reach = total enrolled across selected classes.
      final rosterCounts = <String, int>{};
      for (final c in classes) {
        final roster = await Repo.roster(c['id'] as String);
        rosterCounts[c['name'] as String] = roster.length;
        examDraft.classIdsByName[c['name'] as String] = c['id'] as String;
      }
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _rosterCounts = rosterCounts;
        _recalcReach();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  Map<String, int> _rosterCounts = {};

  void _recalcReach() {
    examDraft.reach = examDraft.targetClasses
        .map((name) => _rosterCounts[name] ?? 0)
        .fold(0, (a, b) => a + b);
  }

  /// In the wide two-column layout each card flexes (3:1). Stacked vertically on
  /// mobile, a card must size to its content — wrapping it in `Expanded` there
  /// (flex 0, tight fit, inside the scroll view) would collapse it to zero height.
  Widget _flex(bool wide, int flex, Widget child) =>
      wide ? Expanded(flex: flex, child: child) : child;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return WizardScaffold(
      appTitle: 'New Exam Wizard',
      stepLabel: 'Step 2 of 3 · Targeting',
      title: 'Target Audience',
      progress: 0.66,
      backRoute: '/wizard/details',
      onNext: () {
        if (examDraft.targetClasses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Select at least one class to continue'),
              backgroundColor: AppColors.error));
          return;
        }
        context.go('/wizard/upload');
      },
      child: Column(
        children: [
          // Target classes + reach
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _flex(wide, 3, AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Target Classes', icon: Icons.school_outlined),
                      const SizedBox(height: 6),
                      Text('Tap a class to include it in this exam.',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 14),
                      if (_classes.isEmpty)
                        Text('Loading classes…',
                            style: Theme.of(context).textTheme.bodySmall),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final c in _classes)
                          _SelectableClassChip(
                            name: c['name'] as String,
                            count: _rosterCounts[c['name']] ?? 0,
                            selected: examDraft.targetClasses
                                .contains(c['name'] as String),
                            onTap: () {
                              setState(() {
                                final name = c['name'] as String;
                                if (!examDraft.targetClasses.remove(name)) {
                                  examDraft.targetClasses.add(name);
                                }
                                _recalcReach();
                              });
                            },
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              _flex(wide, 1, AppCard(
                  color: AppColors.surfaceContainer,
                  child: Column(children: [
                    const Icon(Icons.groups, color: AppColors.primary, size: 28),
                    const SizedBox(height: 10),
                    FieldLabel('Total Reach'),
                    Text('${examDraft.reach}',
                        style: AppTheme.mono(40, FontWeight.w700,
                            color: AppColors.onSurface, ls: -1)),
                    const SizedBox(height: 6),
                    Text('Students across ${examDraft.targetClasses.length} selected classes',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableClassChip extends StatelessWidget {
  const _SelectableClassChip(
      {required this.name,
      required this.count,
      required this.selected,
      required this.onTap});
  final String name;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryStrong.withValues(alpha: 0.16)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.outline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 14,
                color: selected ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 8),
            Flexible(
              child: Text('$name · $count students',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.mono(12, FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.onSurface,
                      ls: 0)),
            ),
          ]),
        ),
      );
}
