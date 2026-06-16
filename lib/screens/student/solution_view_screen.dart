import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class SolutionViewScreen extends StatelessWidget {
  const SolutionViewScreen({super.key});

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
          title: Text('Solution Review',
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
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_fix_high,
                      size: 40, color: AppColors.teal),
                ),
                const SizedBox(height: 24),
                Text('Coming Soon',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Step-by-step AI solutions for each exam question will '
                  'appear here once the solution review feature is connected '
                  'to real exam submissions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                AppButton('Back to Analysis',
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
