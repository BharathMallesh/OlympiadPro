import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});
  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _code = TextEditingController(text: 'MKT-2024-X');
  bool _verified = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/student/interests',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              // Reached from the hub via push -> pop back to the hub. During
              // onboarding (reached via go) there's nothing to pop, so fall
              // back to the previous setup step.
              onPressed: () => popOrGo(context, '/student/interests')),
          title: Text('Vidyora',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('Step 3 of 3',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('Final Step: Join Your Class',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                        'Enter the unique class code provided by your teacher to '
                        'sync your assignments and track progress.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    color: AppColors.surfaceContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Class Code'),
                        Row(children: [
                          Expanded(child: AppInput(controller: _code)),
                          const SizedBox(width: 10),
                          AppButton('Verify',
                              onPressed: () => setState(() => _verified = true)),
                        ]),
                        const SizedBox(height: 10),
                        Text('Case-sensitive identifier provided via syllabus or email.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_verified) ...[
                    AppCard(
                      accentTop: AppColors.teal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            StatusChip('Match Found',
                                color: AppColors.teal, filled: true),
                            const Spacer(),
                            const Icon(Icons.settings_outlined,
                                size: 18, color: AppColors.muted),
                          ]),
                          const SizedBox(height: 16),
                          Text('Advanced Calculus - Section A',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 18),
                          Row(children: const [
                            Expanded(
                              child: _Meta('Instructor', 'Dr. Aris Thorne',
                                  Icons.person_outline),
                            ),
                            Expanded(
                              child: _Meta('Population', '42 Students enrolled',
                                  Icons.groups_outlined),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          const _Meta('School / Institute', 'Excellence Academy',
                              Icons.account_balance_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton('Complete Setup & Enter Dashboard',
                        expand: true,
                        trailingIcon: Icons.rocket_launch_outlined,
                        onPressed: () => context.go('/student/hub')),
                  ] else
                    AppButton('Skip for now — Enter Dashboard',
                        kind: AppBtnKind.ghost,
                        expand: true,
                        onPressed: () => context.go('/student/hub')),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                        'By completing setup, you agree to share your activity '
                        'logs with the assigned instructor.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
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

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTheme.mono(9, FontWeight.w500, ls: 0.8)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      );
}
