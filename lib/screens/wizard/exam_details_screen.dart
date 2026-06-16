import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/common.dart';
import 'wizard_shell.dart';

class ExamDetailsScreen extends StatefulWidget {
  const ExamDetailsScreen({super.key});
  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  static const _categories = ['JEE', 'NEET', 'PG CET', 'CBSE', 'State Board', 'Add Other'];

  final TextEditingController _title =
      TextEditingController(text: examDraft.title);
  final TextEditingController _description =
      TextEditingController(text: examDraft.description);
  final TextEditingController _duration =
      TextEditingController(text: examDraft.duration.toString());

  @override
  void initState() {
    super.initState();
    _title.addListener(() => examDraft.title = _title.text);
    _description
        .addListener(() => examDraft.description = _description.text);
    _duration.addListener(
        () => examDraft.duration = int.tryParse(_duration.text) ?? 90);
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      appTitle: 'Create New Exam',
      stepLabel: 'Step 1 of 4 · Exam Details',
      title: 'Primary Information',
      progress: 0.25,
      backRoute: '/dashboard',
      nextRoute: '/wizard/audience',
      nextLabel: 'Continue',
      nextKind: AppBtnKind.primary,
      sideRail: _SideRail(),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Primary Information', icon: Icons.info_outline),
            const SizedBox(height: 20),
            const FieldLabel('Exam Title'),
            AppInput(
              hint: 'e.g. Advanced Calculus Olympiad 2024',
              controller: _title,
            ),
            const SizedBox(height: 6),
            Text('Ensure titles are descriptive for student dashboards.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            const FieldLabel('Exam Category / Board'),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 560 ? 3 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: cols == 3 ? 3 : 3.4,
                children: [
                  for (final cat in _categories)
                    SelectTile(cat,
                        selected: examDraft.board == cat,
                        onTap: () => setState(() => examDraft.board = cat)),
                ],
              );
            }),
            const SizedBox(height: 18),
            const FieldLabel('Target Audience'),
            const AppInput(
                hint: 'Select Category First', icon: Icons.groups_outlined),
            const SizedBox(height: 18),
            const FieldLabel('Exam Description'),
            AppInput(
                controller: _description,
                hint: 'Enter instructions, syllabus coverage, or required materials...',
                maxLines: 4),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Duration (min)'),
                    AppInput(
                        controller: _duration,
                        suffix: const Icon(Icons.schedule, size: 18, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    FieldLabel('Format'),
                    AppInput(hint: 'Mock Exam', suffix: Icon(Icons.keyboard_arrow_down, color: AppColors.muted)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intelligent Suggestions',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Select an exam category to see tailored suggestions.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          color: AppColors.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppColors.muted, size: 32),
              ),
              const SizedBox(height: 12),
              Text('Academic Standards',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                  'Ensure your exam complies with relevant Board standards. '
                  'Category selection updates the target audience options.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel('Setup Progress'),
              const SizedBox(height: 8),
              for (final (label, done) in const [
                ('Details', true),
                ('Audience', false),
                ('Schedule', false),
                ('Bank', false),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(done ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16,
                        color: done ? AppColors.primary : AppColors.muted),
                    const SizedBox(width: 10),
                    Text(label,
                        style: TextStyle(
                            color: done ? AppColors.onSurface : AppColors.muted,
                            fontSize: 13)),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
