import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/drafts.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class OnboardingFinalizeScreen extends StatefulWidget {
  const OnboardingFinalizeScreen({super.key});
  @override
  State<OnboardingFinalizeScreen> createState() =>
      _OnboardingFinalizeScreenState();
}

class _OnboardingFinalizeScreenState extends State<OnboardingFinalizeScreen> {
  bool _busy = false;

  Future<void> _activate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final d = onboardingDraft;
      await Repo.teacherRegister(
        email: d.email,
        password: d.password,
        fullName: d.fullName,
        institutionName: d.institutionName,
      );
      if (d.className.isNotEmpty) {
        await Repo.createClass(d.className,
            grade: d.grade.isEmpty ? null : d.grade,
            section: d.section.isEmpty ? null : d.section);
      }
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/register/institution',
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _brandBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip('Verification Complete',
                            color: AppColors.success, icon: Icons.check_circle),
                        const SizedBox(height: 16),
                        Text('Final Review &\nConfirmation',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 12),
                        Text(
                            'Your academic profile is validated and ready for the '
                            '2024-25 competition cycle.',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 24),

                        // Faculty card
                        AppCard(
                          accentTop: AppColors.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: const Icon(Icons.person_outline,
                                      color: AppColors.muted),
                                ),
                                const Spacer(),
                                Text('ID: OPRO-9421',
                                    style: AppTheme.mono(11, FontWeight.w500)),
                              ]),
                              const SizedBox(height: 20),
                              const FieldLabel('Faculty Member'),
                              Text(
                                  onboardingDraft.fullName.isEmpty
                                      ? 'New Educator'
                                      : onboardingDraft.fullName,
                                  style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                  onboardingDraft.title.isEmpty
                                      ? 'Educator'
                                      : onboardingDraft.title,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(children: [
                                StatusChip('PhD', color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 8),
                                StatusChip('Physics',
                                    color: AppColors.onSurfaceVariant),
                                const Spacer(),
                                Text('Edit Profile',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: AppColors.primary)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Institution card
                        AppCard(
                          accentTop: AppColors.teal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.tealStrong.withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: const Icon(Icons.apartment,
                                      color: AppColors.teal),
                                ),
                                const Spacer(),
                                StatusChip('Verified',
                                    color: AppColors.success,
                                    icon: Icons.verified_outlined),
                              ]),
                              const SizedBox(height: 20),
                              const FieldLabel('Institution'),
                              Text(onboardingDraft.institutionName,
                                  style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                  [
                                    onboardingDraft.className,
                                    if (onboardingDraft.grade.isNotEmpty)
                                      onboardingDraft.grade,
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                            _busy ? 'Creating Account…' : 'Enter Dashboard',
                            expand: true,
                            trailingIcon: Icons.arrow_forward,
                            onPressed: _activate),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/register/institution'),
                            child: const Text('Back to edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _brandBar(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outline)),
        ),
        child: Row(children: [
          const Icon(Icons.school_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('OlympiadPro',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ]),
      );
}
