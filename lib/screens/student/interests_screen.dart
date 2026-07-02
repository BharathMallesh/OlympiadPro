import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../widgets/common.dart';
import '../../widgets/help_dialog.dart';

class AcademicInterestsScreen extends StatefulWidget {
  const AcademicInterestsScreen({super.key});
  @override
  State<AcademicInterestsScreen> createState() => _AcademicInterestsScreenState();
}

class _AcademicInterestsScreenState extends State<AcademicInterestsScreen> {
  String _exam = 'JEE';
  final _subjects = {'Mathematics': true, 'Physics': true, 'Chemistry': false, 'Biology': false};

  static const _subjectIcons = {
    'Mathematics': Icons.functions,
    'Physics': Icons.bolt,
    'Chemistry': Icons.science_outlined,
    'Biology': Icons.biotech_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/student/register',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/student/register')),
          title: Text('Vidyora',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          actions: const [
            HelpButton(title: 'Choosing your interests', tips: [
              (
                'Target exams',
                'Pick the exams you are preparing for. We use these to tailor your AI practice sets and recommendations.'
              ),
              (
                'Subjects',
                'Select the subjects you want to focus on. You can change these any time from your profile.'
              ),
              (
                'Why we ask',
                'These preferences personalise your practice — they are not shared with other students.'
              ),
            ]),
            SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(children: [
                    Row(children: [
                      Text('ONBOARDING',
                          style: AppTheme.mono(10, FontWeight.w600, ls: 1.2)),
                      const Spacer(),
                      Text('Step 2 of 3',
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                    const SizedBox(height: 8),
                    const ProgressLine(0.66, height: 5),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text('Academic Interests',
                              style: Theme.of(context).textTheme.headlineLarge),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                              'Select your target exams and subjects to personalize '
                              'your study dashboard and receive relevant mock test '
                              'notifications.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        const SizedBox(height: 24),
                        AppCard(
                          accentTop: AppColors.teal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionTitle('Target Exam',
                                  icon: Icons.fact_check_outlined,
                                  color: AppColors.teal),
                              const SizedBox(height: 8),
                              Text(
                                  'NEET & JEE follow the NCERT syllabus; CET '
                                  'follows the State Board syllabus.',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 14),
                              Wrap(spacing: 10, runSpacing: 10, children: [
                                for (final e in ExamScope.exams)
                                  _ExamChip(
                                    label: e,
                                    selected: _exam == e,
                                    onTap: () => setState(() => _exam = e),
                                  ),
                              ]),
                              const SizedBox(height: 12),
                              Text('$_exam · ${ExamScope.curriculumFor(_exam)} syllabus',
                                  style: AppTheme.mono(11, FontWeight.w700,
                                      color: AppColors.teal)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppCard(
                          accentTop: AppColors.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionTitle('Core Subjects',
                                  icon: Icons.menu_book_outlined),
                              const SizedBox(height: 14),
                              for (final s in _subjects.entries)
                                _SubjectRow(
                                  label: s.key,
                                  icon: _subjectIcons[s.key]!,
                                  selected: s.value,
                                  onTap: () =>
                                      setState(() => _subjects[s.key] = !s.value),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                            'You can update these preferences anytime from your '
                            'profile settings.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton('Continue',
                      expand: true,
                      onPressed: () => context.go('/student/join-class')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamChip extends StatelessWidget {
  const _ExamChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.tealStrong.withValues(alpha: 0.2)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.teal : AppColors.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(12, FontWeight.w500,
                  color: selected ? AppColors.teal : AppColors.onSurfaceVariant)),
        ),
      );
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outline),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryStrong.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.success : AppColors.muted,
              ),
            ]),
          ),
        ),
      );
}
