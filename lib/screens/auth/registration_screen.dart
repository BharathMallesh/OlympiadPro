import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/drafts.dart';
import '../../widgets/common.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _name = TextEditingController(text: onboardingDraft.fullName);
  final _email = TextEditingController(text: onboardingDraft.email);
  final _password = TextEditingController(text: onboardingDraft.password);
  final _title = TextEditingController(text: onboardingDraft.title);
  bool _obscure = true;

  void _continue() {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name, email, and a password of 8+ characters are required'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    onboardingDraft
      ..fullName = _name.text.trim()
      ..email = _email.text.trim()
      ..password = _password.text
      ..title = _title.text.trim();
    context.go('/register/institution');
  }

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
                              AppInput(
                                  controller: _name,
                                  hint: 'Dr. Julian Thorne'),
                              const SizedBox(height: 16),
                              const FieldLabel('Email Address'),
                              AppInput(
                                  controller: _email,
                                  hint: 'j.thorne@university.edu'),
                              const SizedBox(height: 16),
                              const FieldLabel('Password'),
                              AppInput(
                                  controller: _password,
                                  hint: 'At least 8 characters',
                                  obscure: _obscure,
                                  suffix: IconButton(
                                    tooltip: _obscure
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: AppColors.muted),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  )),
                              const SizedBox(height: 16),
                              const FieldLabel('Professional Title'),
                              AppInput(
                                  controller: _title,
                                  hint: 'Senior Faculty of Competitive Math'),
                              const SizedBox(height: 20),
                              AppButton('Continue',
                                  expand: true,
                                  trailingIcon: Icons.arrow_forward,
                                  onPressed: _continue),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Text(
                              '© 2026 VIDYORA · EXCELLENCE IN ACADEMIC COMPETITION',
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
          Text('Vidyora',
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
