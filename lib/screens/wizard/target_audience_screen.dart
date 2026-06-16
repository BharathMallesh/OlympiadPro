import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'wizard_shell.dart';

class TargetAudienceScreen extends StatefulWidget {
  const TargetAudienceScreen({super.key});
  @override
  State<TargetAudienceScreen> createState() => _TargetAudienceScreenState();
}

class _TargetAudienceScreenState extends State<TargetAudienceScreen> {
  final _students = <String, bool>{};
  String _group = '';
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
        for (final s in roster) {
          _students.putIfAbsent(s['full_name'] as String, () => true);
        }
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

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return WizardScaffold(
      appTitle: 'New Exam Wizard',
      stepLabel: 'Step 2 of 4 · Targeting',
      title: 'Target Audience',
      progress: 0.5,
      backRoute: '/wizard/details',
      nextRoute: '/wizard/scheduling',
      child: Column(
        children: [
          // Target classes + reach
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: wide ? 3 : 0,
                child: AppCard(
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
              Expanded(
                flex: wide ? 1 : 0,
                child: AppCard(
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
          const SizedBox(height: 16),

          // Student selection + quick groups
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: wide ? 1 : 0,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: SectionTitle('Student Selection',
                                icon: Icons.person_search_outlined)),
                        _Toggle(),
                      ]),
                      const SizedBox(height: 12),
                      for (final entry in _students.entries)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.trailing,
                          value: entry.value,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          onChanged: (v) =>
                              setState(() => _students[entry.key] = v ?? false),
                          title: Row(children: [
                            InitialsAvatar(entry.key, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(entry.key,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(
                flex: wide ? 1 : 0,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Quick Groups', icon: Icons.dashboard_customize_outlined),
                      const SizedBox(height: 6),
                      Text('Select pre-defined smart groups based on performance metrics.',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 14),
                      for (final (label, sub, icon, color) in [
                        ('Top Performers', 'Score > 90%', Icons.trending_up, AppColors.success),
                        ('Needs Improvement', 'Score < 40%', Icons.warning_amber, AppColors.secondary),
                        ('Median Batch', 'Consistency: High', Icons.bar_chart, AppColors.primary),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _GroupRow(
                            label: label, sub: sub, icon: icon, color: color,
                            selected: _group == label,
                            onTap: () => setState(() => _group = label),
                          ),
                        ),
                    ],
                  ),
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

class _Toggle extends StatefulWidget {
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _all = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(children: [
        for (final (label, isAll) in [('All', true), ('Specific', false)])
          InkWell(
            onTap: () => setState(() => _all = isAll),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _all == isAll
                    ? AppColors.primaryStrong.withValues(alpha: 0.25)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(label,
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: _all == isAll ? AppColors.primary : AppColors.muted)),
            ),
          ),
      ]),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.label, required this.sub, required this.icon,
    required this.color, required this.selected, required this.onTap,
  });
  final String label, sub;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? color : AppColors.outline),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sub, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18, color: selected ? color : AppColors.muted),
        ]),
      ),
    );
  }
}
