import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

class PracticeGeneratorScreen extends StatefulWidget {
  const PracticeGeneratorScreen({super.key});
  @override
  State<PracticeGeneratorScreen> createState() => _PracticeGeneratorScreenState();
}

class _PracticeGeneratorScreenState extends State<PracticeGeneratorScreen> {
  final _subjects = {'Math': true, 'Physics': false, 'Chemistry': false, 'Biology': false};
  double _questions = 45;
  String _timeLimit = '60m';
  final _mathTopics = {
    'Calculus: Limits & Continuity': true,
    'Coordinate Geometry': true,
    'Vectors & 3D Geometry': false,
    'Probability': false,
  };

  static const _subjectIcons = {
    'Math': Icons.functions,
    'Physics': Icons.bolt,
    'Chemistry': Icons.science_outlined,
    'Biology': Icons.biotech_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'OlympiadPro',
      currentTab: 1,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Hub  /  Mock Test Engine',
                      style: AppTheme.mono(10, FontWeight.w500, ls: 0.5)),
                  const SizedBox(height: 8),
                  Text('Create Specialized Mock Test',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                      'Configure your elite preparation environment. Select '
                      'parameters, set rigorous goals, and focus on high-impact '
                      'chapters.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),

                  // 1 — Exam parameters
                  _NumberedCard(
                    number: '1',
                    title: 'Exam Parameters',
                    accent: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Select Subjects'),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (final s in _subjects.entries)
                            InkWell(
                              onTap: () =>
                                  setState(() => _subjects[s.key] = !s.value),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: s.value
                                      ? AppColors.primaryStrong
                                          .withValues(alpha: 0.2)
                                      : AppColors.surfaceContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(
                                      color: s.value
                                          ? AppColors.primary
                                          : AppColors.outline),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_subjectIcons[s.key], size: 14,
                                          color: s.value
                                              ? AppColors.primary
                                              : AppColors.muted),
                                      const SizedBox(width: 6),
                                      Text(s.key,
                                          style: AppTheme.mono(12, FontWeight.w500,
                                              color: s.value
                                                  ? AppColors.primary
                                                  : AppColors.onSurfaceVariant)),
                                    ]),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          height: 90,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Text('MULTI-DISCIPLINARY FOCUS',
                              style: AppTheme.mono(10, FontWeight.w600, ls: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2 — Goal setting
                  _NumberedCard(
                    number: '2',
                    title: 'Goal Setting',
                    accent: AppColors.teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Expanded(child: FieldLabel('Number of Questions')),
                          Text('${_questions.round()}',
                              style: AppTheme.mono(16, FontWeight.w700,
                                  color: AppColors.teal)),
                        ]),
                        Slider(
                          value: _questions,
                          min: 10, max: 90, divisions: 16,
                          activeColor: AppColors.teal,
                          onChanged: (v) => setState(() => _questions = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10', style: AppTheme.mono(10, FontWeight.w500)),
                            Text('90', style: AppTheme.mono(10, FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const FieldLabel('Time Limit (Minutes)'),
                        Row(children: [
                          for (final t in ['30m', '60m', '180m']) ...[
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _timeLimit = t),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _timeLimit == t
                                        ? AppColors.tealStrong
                                            .withValues(alpha: 0.2)
                                        : AppColors.scaffold,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                        color: _timeLimit == t
                                            ? AppColors.teal
                                            : AppColors.outlineStrong),
                                  ),
                                  child: Text(t,
                                      style: AppTheme.mono(13, FontWeight.w600,
                                          color: _timeLimit == t
                                              ? AppColors.teal
                                              : AppColors.muted)),
                                ),
                              ),
                            ),
                            if (t != '180m') const SizedBox(width: 10),
                          ],
                        ]),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tealStrong.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.info_outline,
                                size: 15, color: AppColors.teal),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: const [
                                  TextSpan(text: 'Selected pace: '),
                                  TextSpan(
                                      text: '1.3 minutes per question',
                                      style: TextStyle(
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.w600)),
                                  TextSpan(
                                      text:
                                          '. This matches the standard JEE Advanced rigor.'),
                                ],
                              )),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3 — Topic focus
                  _NumberedCard(
                    number: '3',
                    title: 'Topic Focus',
                    accent: AppColors.success,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                          onPressed: () => setState(() => _mathTopics
                              .updateAll((k, v) => true)),
                          child: const Text('Select All')),
                      TextButton(
                          onPressed: () => setState(() =>
                              _mathTopics.updateAll((k, v) => false)),
                          child: const Text('Clear')),
                    ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MATHEMATICS',
                            style: AppTheme.mono(10, FontWeight.w600,
                                color: AppColors.primary, ls: 1)),
                        const SizedBox(height: 6),
                        for (final t in _mathTopics.entries)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                            checkColor: AppColors.onPrimary,
                            value: t.value,
                            onChanged: (v) => setState(
                                () => _mathTopics[t.key] = v ?? false),
                            title: Text(t.key,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontSize: 14)),
                          ),
                        const Divider(),
                        for (final s in ['PHYSICS', 'CHEMISTRY', 'BIOLOGY']) ...[
                          const SizedBox(height: 8),
                          Text(s,
                              style:
                                  AppTheme.mono(10, FontWeight.w600, ls: 1)),
                          const SizedBox(height: 4),
                          Text(
                              'Select ${s.toLowerCase()} to enable topics',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppButton('Generate & Start',
                expand: true,
                trailingIcon: Icons.play_arrow,
                onPressed: () => context.push('/student/exam')),
          ),
        ],
      ),
    );
  }
}

class _NumberedCard extends StatelessWidget {
  const _NumberedCard({
    required this.number, required this.title,
    required this.accent, required this.child, this.trailing,
  });
  final String number, title;
  final Color accent;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentTop: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Text(number,
                  style: AppTheme.mono(13, FontWeight.w700, color: accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ?trailing,
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
