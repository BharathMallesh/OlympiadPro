import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/mock.dart';
import '../../widgets/common.dart';

class UploadPaperScreen extends StatefulWidget {
  const UploadPaperScreen({super.key});
  @override
  State<UploadPaperScreen> createState() => _UploadPaperScreenState();
}

class _UploadPaperScreenState extends State<UploadPaperScreen> {
  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return PopRedirect(
      fallbackRoute: '/wizard/scheduling',
      child: Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: () => context.go('/dashboard')),
        title: Text('OlympiadPro',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: InitialsAvatar('Aris Thorne', size: 32),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PHASE 01',
                              style: AppTheme.mono(12, FontWeight.w600,
                                  color: AppColors.secondary, ls: 1.5)),
                          const SizedBox(height: 6),
                          Text('Step 1: Upload PDF',
                              style: Theme.of(context).textTheme.headlineLarge),
                        ],
                      ),
                    ),
                    Row(children: [
                      for (var i = 0; i < 3; i++) ...[
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i == 0 ? AppColors.primary : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ]),
                  ],
                ),
                const SizedBox(height: 24),
                Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: Column(
                        children: [
                          _DropZone(),
                          const SizedBox(height: 16),
                          _UploadProgress(fileName: examDraft.fileName),
                        ],
                      ),
                    ),
                    SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 16),
                    Expanded(
                      flex: wide ? 2 : 0,
                      child: Column(
                        children: [
                          _ParsingEngine(
                            selected: examDraft.parsingEngine,
                            onSelect: (v) => setState(() => examDraft.parsingEngine = v),
                          ),
                          const SizedBox(height: 16),
                          _Instructions(),
                          const SizedBox(height: 16),
                          AppButton('Continue to Processing',
                              kind: AppBtnKind.secondary,
                              expand: true,
                              trailingIcon: Icons.arrow_forward,
                              onPressed: () => context.go('/wizard/ai-review')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _DropZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.outlineStrong,
            style: BorderStyle.solid,
            width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 18),
          Text('Select PDF File',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('or drag and drop here',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          AppButton('Browse Files',
              kind: AppBtnKind.primary, icon: Icons.upload_file, onPressed: () {}),
        ],
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.fileName});
  final String fileName;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(fileName,
                    style: Theme.of(context).textTheme.titleMedium)),
            Text('Uploading... 65%',
                style: AppTheme.mono(12, FontWeight.w600,
                    color: AppColors.secondary)),
          ]),
          const SizedBox(height: 12),
          const ProgressLine(0.65, color: AppColors.secondaryStrong, height: 6),
        ],
      ),
    );
  }
}

class _ParsingEngine extends StatelessWidget {
  const _ParsingEngine({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('AI PARSING ENGINE',
                style: AppTheme.mono(11, FontWeight.w600,
                    color: AppColors.primary, ls: 1)),
          ]),
          const SizedBox(height: 14),
          _engineOption('Standard', 'Fast processing', selected == 'Standard'),
          const SizedBox(height: 10),
          _engineOption('Advanced', 'Precise LaTeX/Diagrams', selected == 'Advanced'),
        ],
      ),
    );
  }

  Widget _engineOption(String title, String sub, bool sel) => InkWell(
        onTap: () => onSelect(title),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: sel ? AppColors.primary : AppColors.outline),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: sel ? AppColors.primary : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(sub,
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: sel ? AppColors.primary : AppColors.muted),
          ]),
        ),
      );
}

class _Instructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text('Instructions',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.success)),
          ]),
          const SizedBox(height: 10),
          Text(
              'Upload high-quality scans for better AI parsing of LaTeX formulas and '
              'geometric diagrams. PDFs with embedded text layers are preferred.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
