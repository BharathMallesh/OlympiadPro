import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Student sign-up: email + password. The teacher code is optional — without
/// it the student practises on the super admin's question bank only.
class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _teacherCode = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name, email, and password are required'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _busy = true);
    try {
      await Repo.studentRegister(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        teacherCode: _teacherCode.text,
      );
      if (mounted) context.go('/student/hub');
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
      fallbackRoute: '/login',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/login')),
          titleSpacing: 0,
          title: Row(children: [
            const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text('OLYMPIADPRO',
                style: AppTheme.mono(16, FontWeight.w700,
                    color: AppColors.onSurface, ls: 1.5)),
          ]),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create your account',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                      'Practise from your school\'s question bank and take '
                      'assigned exams.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  const FieldLabel('Full Name'),
                  AppInput(
                      controller: _name,
                      icon: Icons.person_outline,
                      hint: 'Enter your full name'),
                  const SizedBox(height: 18),
                  const FieldLabel('Email Address'),
                  AppInput(
                      controller: _email,
                      icon: Icons.mail_outline,
                      hint: 'student@school.edu'),
                  const SizedBox(height: 18),
                  const FieldLabel('Password (min 8 characters)'),
                  AppInput(
                    controller: _password,
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    hint: '••••••••',
                    suffix: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.muted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('Teacher Code (optional)'),
                  AppInput(
                      controller: _teacherCode,
                      icon: Icons.key_outlined,
                      hint: 'e.g. 85757FE4'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                        'Have a code from your teacher? Enter it to unlock '
                        'their question bank and class exams. Without a code '
                        'you can still practise on the school\'s shared bank.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const SizedBox(height: 28),
                  AppButton(_busy ? 'Creating account…' : 'Create Account',
                      expand: true, onPressed: _busy ? null : _register),
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
