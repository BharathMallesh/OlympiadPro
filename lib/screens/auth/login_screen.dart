import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'educator@olympiadpro.edu');
  final _password = TextEditingController(text: 'password');
  bool _obscure = true;
  bool _isStudent = false;

  String get _homeRoute => _isStudent ? '/student/hub' : '/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: AppColors.onPrimary, size: 34),
                ),
                const SizedBox(height: 16),
                Text('OlympiadPro',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('EXCELLENCE IN ACADEMIC COMPETITION',
                    style: AppTheme.mono(11, FontWeight.w500, ls: 1.5)),
                const SizedBox(height: 24),
                // Role selector: educator vs student portal
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(children: [
                    for (final (label, icon, student) in const [
                      ('Educator', Icons.co_present_outlined, false),
                      ('Student', Icons.school_outlined, true),
                    ])
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isStudent = student),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isStudent == student
                                  ? (student
                                      ? AppColors.tealStrong.withValues(alpha: 0.25)
                                      : AppColors.primaryStrong.withValues(alpha: 0.25))
                                  : null,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 16,
                                    color: _isStudent == student
                                        ? (student ? AppColors.teal : AppColors.primary)
                                        : AppColors.muted),
                                const SizedBox(width: 8),
                                Text(label,
                                    style: AppTheme.mono(12, FontWeight.w600,
                                        color: _isStudent == student
                                            ? (student
                                                ? AppColors.teal
                                                : AppColors.primary)
                                            : AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                AppCard(
                  accentTop: _isStudent ? AppColors.teal : AppColors.primary,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text('Access your academic dashboard and materials.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      const FieldLabel('Email Address'),
                      AppInput(
                          controller: _email,
                          icon: Icons.mail_outline,
                          hint: 'educator@olympiadpro.edu'),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const FieldLabel('Password'),
                          InkWell(
                            onTap: () => context.push('/forgot-password'),
                            child: Text('Forgot Password?',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                      AppInput(
                        controller: _password,
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18, color: AppColors.muted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton('Sign In',
                          expand: true,
                          onPressed: () => context.go(_homeRoute)),
                      const SizedBox(height: 22),
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('INSTITUTIONAL ACCESS',
                              style: AppTheme.mono(10, FontWeight.w500, ls: 1.2)),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: AppButton('Google',
                                kind: AppBtnKind.ghost,
                                icon: Icons.g_mobiledata,
                                expand: true,
                                onPressed: () => context.go(_homeRoute))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: AppButton('SSO',
                                kind: AppBtnKind.ghost,
                                icon: Icons.account_balance_outlined,
                                expand: true,
                                onPressed: () => context.go(_homeRoute))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go(
                      _isStudent ? '/student/register' : '/register'),
                  child: Text.rich(TextSpan(
                    text: _isStudent ? "New student?  " : "New educator?  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const [
                      TextSpan(
                          text: 'Create an account',
                          style: TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
