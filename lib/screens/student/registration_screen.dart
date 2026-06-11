import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class StudentRegistrationScreen extends StatelessWidget {
  const StudentRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/login',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          titleSpacing: 16,
          title: Row(children: [
            const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text('ACADEMIA PRO',
                style: AppTheme.mono(16, FontWeight.w700,
                    color: AppColors.onSurface, ls: 1.5)),
          ]),
          actions: const [
            Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
            SizedBox(width: 16),
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
                  Row(children: [
                    Text('STEP 1 OF 3',
                        style: AppTheme.mono(12, FontWeight.w600,
                            color: AppColors.onSurface, ls: 1.2)),
                    const Spacer(),
                    Text('PERSONAL DETAILS',
                        style: AppTheme.mono(12, FontWeight.w500, ls: 1.2)),
                  ]),
                  const SizedBox(height: 12),
                  const ProgressLine(0.33, height: 5),
                  const SizedBox(height: 36),
                  Text('Create your profile',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                      'Tell us a bit about yourself to get started with your '
                      'elite preparation.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  const FieldLabel('Full Name'),
                  const AppInput(hint: 'Enter your full name'),
                  const SizedBox(height: 20),
                  const FieldLabel('Email Address'),
                  const AppInput(hint: 'email@university.edu'),
                  const SizedBox(height: 20),
                  const FieldLabel('Current Grade / Year'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.scaffold,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.outlineStrong),
                    ),
                    child: Row(children: const [
                      Text('Class 10', style: TextStyle(color: AppColors.onSurface)),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 20),
                    ]),
                  ),
                  const SizedBox(height: 48),
                  AppButton('Continue',
                      expand: true,
                      onPressed: () => context.go('/student/interests')),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text.rich(TextSpan(
                        text: 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: const [
                          TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )),
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
