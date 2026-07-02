import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/exam_scope.dart';
import '../../data/stores.dart';
import '../../widgets/common.dart';
import 'wizard_shell.dart';

class ExamDetailsScreen extends StatefulWidget {
  const ExamDetailsScreen({super.key});
  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
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
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      appTitle: 'Create New Exam',
      stepLabel: 'Step 1 of 3 · Exam Details',
      title: 'Primary Information',
      progress: 0.33,
      backRoute: '/dashboard',
      nextLabel: 'Continue',
      nextKind: AppBtnKind.primary,
      onNext: () {
        if (_title.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Enter an exam title to continue'),
              backgroundColor: AppColors.error));
          return;
        }
        examDraft.title = _title.text.trim();
        context.go('/wizard/audience');
      },
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
            const FieldLabel('Target Exam'),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 560 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: cols == 4 ? 2.6 : 3.4,
                children: [
                  for (final cat in ExamScope.exams)
                    SelectTile(cat,
                        selected: ExamScope.normalize(examDraft.board) == cat,
                        onTap: () => setState(() => examDraft.board = cat)),
                ],
              );
            }),
            const SizedBox(height: 8),
            Text(
                ExamScope.normalize(examDraft.board) == null
                    ? 'NEET & JEE follow NCERT; CET & PUC follow the State Board / '
                        'PUC syllabus.'
                    : '${ExamScope.normalize(examDraft.board)} · '
                        '${ExamScope.curriculumFor(examDraft.board)} syllabus',
                style: AppTheme.mono(11, FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 18),
            const FieldLabel('Exam Description'),
            AppInput(
                controller: _description,
                hint: 'Enter instructions, syllabus coverage, or required materials...',
                maxLines: 4),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Duration (min)'),
                AppInput(
                    controller: _duration,
                    suffix: const Icon(Icons.schedule,
                        size: 18, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
