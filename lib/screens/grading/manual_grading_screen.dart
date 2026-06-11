import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/common.dart';

class ManualGradingScreen extends StatefulWidget {
  const ManualGradingScreen({super.key, this.submissionId = ''});
  final String submissionId;
  @override
  State<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends State<ManualGradingScreen> {
  double _marks = 6;
  String _classification = '';

  String get _studentName {
    for (final s in Mock.submissions) {
      if (s.student.id == widget.submissionId) return s.student.name;
    }
    return 'Arjun Mehta';
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: '/grading/submissions',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => popOrGo(context, '/grading/submissions')),
        titleSpacing: 0,
        title: Row(children: [
          Text('Manual Grading',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 12),
          Flexible(
            child: Text('· $_studentName',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]),
        actions: [
          StatusChip('Live Grading Session',
              color: AppColors.success, icon: Icons.circle),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: handwritten proof + scratchpad
            Expanded(
              flex: wide ? 3 : 0,
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Handwritten Proof',
                            icon: Icons.draw_outlined),
                        const SizedBox(height: 14),
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: const Color(0xFF14110A),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gesture, color: AppColors.muted, size: 40),
                                SizedBox(height: 10),
                                Text('Scanned proof — student handwriting',
                                    style: TextStyle(color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Annotation toolbar
                        Wrap(spacing: 8, children: [
                          for (final icon in const [
                            Icons.edit, Icons.highlight, Icons.straighten,
                            Icons.crop_free, Icons.zoom_in, Icons.undo, Icons.redo,
                          ])
                            _ToolBtn(icon),
                          const Spacer(),
                          _ToolBtn(Icons.check_circle, color: AppColors.success),
                          _ToolBtn(Icons.cancel, color: AppColors.error),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Digital Scratchpad',
                            icon: Icons.functions),
                        const SizedBox(height: 14),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Center(
                            child: Icon(Icons.show_chart,
                                color: AppColors.primary, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 16),

            // Right: step-by-step marking
            Expanded(
              flex: wide ? 2 : 0,
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Step-by-Step Marking',
                            icon: Icons.checklist),
                        const SizedBox(height: 16),
                        _MarkStep(
                          ok: true,
                          title: '1. Boundary Condition Definition',
                          detail: 'Correctly identified the limits of integration '
                              'for the multi-variable surface.',
                          marks: '+2.0',
                        ),
                        _MarkStep(
                          ok: false,
                          title: '2. Partial Derivatives Expansion',
                          detail: 'Missed the chain rule application on the third term.',
                          marks: '-1.5',
                        ),
                        _MarkStep(
                          ok: true,
                          title: '3. Convergence Test Verification',
                          detail: 'Applied ratio test correctly to confirm convergence.',
                          marks: '+2.0',
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Add Marking Criteria'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel('Error Classification'),
                        const SizedBox(height: 10),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (final (label, color) in const [
                            ('Calculation Slip', AppColors.secondary),
                            ('Conceptual Gap', AppColors.error),
                            ('Logical Fallacy', AppColors.primary),
                          ])
                            _ErrChip(
                              label: label, color: color,
                              selected: _classification == label,
                              onTap: () => setState(() => _classification = label),
                            ),
                        ]),
                        const SizedBox(height: 20),
                        Row(children: [
                          FieldLabel('Marks Awarded'),
                          const Spacer(),
                          Text('${_marks.toStringAsFixed(1)} / 10.0',
                              style: AppTheme.mono(16, FontWeight.w700,
                                  color: AppColors.secondary)),
                        ]),
                        Slider(
                          value: _marks,
                          min: 0, max: 10, divisions: 20,
                          activeColor: AppColors.secondary,
                          onChanged: (v) => setState(() => _marks = v),
                        ),
                        const SizedBox(height: 8),
                        AppButton('Submit & Next Student',
                            kind: AppBtnKind.secondary,
                            expand: true,
                            trailingIcon: Icons.arrow_forward,
                            onPressed: () =>
                                popOrGo(context, '/grading/submissions')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn(this.icon, {this.color});
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Icon(icon, size: 16, color: color ?? AppColors.onSurfaceVariant),
      );
}

class _MarkStep extends StatelessWidget {
  const _MarkStep({
    required this.ok, required this.title,
    required this.detail, required this.marks,
  });
  final bool ok;
  final String title, detail, marks;
  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(marks, style: AppTheme.mono(13, FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ErrChip extends StatelessWidget {
  const _ErrChip({
    required this.label, required this.color,
    required this.selected, required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.25 : 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.4)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
