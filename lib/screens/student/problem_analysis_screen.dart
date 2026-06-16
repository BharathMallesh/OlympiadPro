import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class ProblemAnalysisScreen extends StatelessWidget {
  const ProblemAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/student/exam-analysis',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/student/exam-analysis')),
          titleSpacing: 0,
          title: Text('Problem Analysis',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.construction_outlined,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text('Coming Soon',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Per-question analysis with AI diagnostics will be available '
                  'once exam submissions are connected to the backend.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                AppButton('Go Back',
                    kind: AppBtnKind.ghost,
                    icon: Icons.arrow_back,
                    onPressed: () => popOrGo(context, '/student/exam-analysis')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
