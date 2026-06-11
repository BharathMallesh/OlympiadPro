import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// #10 — Class roster: approve/reject pending join requests and manage
/// enrolled students.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _pending = <(String, String)>[
    ('Rohan Iyer', 'Code MKT-2024-X · requested 2h ago'),
    ('Sneha Patel', 'Code MKT-2024-X · requested 1d ago'),
  ];
  final _enrolled = <(String, String, Color)>[
    ('Elena Sideris', 'JEE-2024-8902 · 92% avg', AppColors.teal),
    ('Julian Martinez', 'JEE-2024-5512 · 78% avg', AppColors.secondary),
    ('Amina Wong', 'JEE-2024-1029 · 61% avg', AppColors.error),
    ('Devika Krishnan', 'JEE-2024-7011 · 84% avg', AppColors.primary),
  ];

  void _resolve(int i, bool approve) {
    final (name, _) = _pending[i];
    setState(() {
      if (approve) {
        _enrolled.add((name, 'NEW · joined just now', AppColors.success));
      }
      _pending.removeAt(i);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(approve ? '$name added to the class.' : '$name request declined.')));
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/analytics/class',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/analytics/class')),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Class Roster', style: Theme.of(context).textTheme.titleLarge),
              Text('Advanced Calculus - Section A',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
          actions: [
            StatusChip('${_enrolled.length} enrolled', color: AppColors.teal),
            const SizedBox(width: 14),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_pending.isNotEmpty) ...[
                  SectionTitle('Pending Requests (${_pending.length})',
                      icon: Icons.hourglass_top, color: AppColors.secondary),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _pending.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        borderColor: AppColors.secondary.withValues(alpha: 0.4),
                        child: Row(children: [
                          InitialsAvatar(_pending[i].$1,
                              size: 40, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pending[i].$1,
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                                Text(_pending[i].$2,
                                    style: AppTheme.mono(9, FontWeight.w500)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Approve',
                            onPressed: () => _resolve(i, true),
                            icon: const Icon(Icons.check_circle,
                                color: AppColors.success),
                          ),
                          IconButton(
                            tooltip: 'Decline',
                            onPressed: () => _resolve(i, false),
                            icon: const Icon(Icons.cancel_outlined,
                                color: AppColors.error),
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 14),
                ],
                SectionTitle('Enrolled Students', icon: Icons.groups_outlined),
                const SizedBox(height: 10),
                for (var i = 0; i < _enrolled.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        InitialsAvatar(_enrolled[i].$1,
                            size: 40, color: _enrolled[i].$3),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_enrolled[i].$1,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text(_enrolled[i].$2,
                                  style: AppTheme.mono(9, FontWeight.w500)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              size: 18, color: AppColors.muted),
                          color: AppColors.surfaceHigh,
                          onSelected: (v) {
                            if (v == 'remove') {
                              final name = _enrolled[i].$1;
                              setState(() => _enrolled.removeAt(i));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content:
                                      Text('$name removed from the class.')));
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                                value: 'profile', child: Text('View profile')),
                            PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove from class',
                                    style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
