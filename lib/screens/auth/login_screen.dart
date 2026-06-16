import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _isStudent = false;
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_isStudent) {
        await Repo.studentLogin(_email.text.trim(), _password.text.trim());
        if (mounted) context.go('/student/hub');
      } else {
        await Repo.teacherLogin(_email.text.trim(), _password.text.trim());
        if (mounted) context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString() == 'unauthorized'
              ? (_isStudent
                  ? 'Invalid email or password'
                  : 'Invalid email or password')
              : e.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                          hint: _isStudent
                              ? 'student@school.edu'
                              : 'educator@olympiadpro.edu'),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const FieldLabel('Password'),
                          if (!_isStudent)
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
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18, color: AppColors.muted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(_busy ? 'Signing In…' : 'Sign In',
                          expand: true, onPressed: _signIn),
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
