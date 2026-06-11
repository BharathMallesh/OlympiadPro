import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/login',
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _Header(onBack: () => context.go('/login')),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Establish Your\nAcademic Profile',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 12),
                        Text(
                            'Welcome, educator. Complete your professional identity '
                            'profile so we can align your expertise with the right '
                            'Olympiad tracks.',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 24),
                        _PhotoCard(),
                        const SizedBox(height: 16),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                StatusChip('STEP 01 / 03', color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text('Personal Information',
                                    style: Theme.of(context).textTheme.titleLarge),
                              ]),
                              const SizedBox(height: 20),
                              const FieldLabel('Full Name'),
                              const AppInput(hint: 'Dr. Julian Thorne'),
                              const SizedBox(height: 16),
                              const FieldLabel('Email Address'),
                              const AppInput(hint: 'j.thorne@university.edu'),
                              const SizedBox(height: 16),
                              const FieldLabel('Password'),
                              const AppInput(hint: '••••••••', obscure: true),
                              const SizedBox(height: 16),
                              const FieldLabel('Faculty Department'),
                              const _FakeDropdown('Select Department'),
                              const SizedBox(height: 16),
                              const FieldLabel('Professional Title'),
                              const AppInput(hint: 'Senior Faculty of Competitive Math'),
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.account_balance_outlined,
                                      size: 16, color: AppColors.teal),
                                  label: Text('Institutional Login',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: AppColors.teal)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppButton('Continue',
                                  expand: true,
                                  trailingIcon: Icons.arrow_forward,
                                  onPressed: () => context.go('/register/institution')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Text(
                              '© 2024 OLYMPIADPRO ACADEMIC SYSTEMS · PROFESSIONAL GRADE EDUCATION',
                              textAlign: TextAlign.center,
                              style: AppTheme.mono(9.5, FontWeight.w500, ls: 0.8)),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Container(
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
          const Spacer(),
          const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.person_outline, size: 18, color: AppColors.muted)),
        ]),
      );
}

class _PhotoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceContainer,
      child: Column(children: [
        Stack(children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, color: AppColors.muted, size: 28),
                SizedBox(height: 8),
                Text('UPLOAD\nPHOTO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 16, color: AppColors.onPrimary),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text('Professional Headshot',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Recommended: 400×400px. JPG or PNG formats only.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _FakeDropdown extends StatelessWidget {
  const _FakeDropdown(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppColors.onSurface)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 20),
        ]),
      );
}
