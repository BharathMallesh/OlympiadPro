import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Self-serve signup for an independent (solo) teacher. Creates their own
/// one-person tenant, publishes their profile, and opens a default class — so
/// they're immediately listed in the student "Find a Teacher" directory.
class IndependentSignupScreen extends StatefulWidget {
  const IndependentSignupScreen({super.key});
  @override
  State<IndependentSignupScreen> createState() => _IndependentSignupScreenState();
}

class _IndependentSignupScreenState extends State<IndependentSignupScreen> {
  static const _allSubjects = ['Physics', 'Chemistry', 'Mathematics', 'Biology'];
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _headline = TextEditingController();
  final Set<String> _subjects = {};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _headline.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _busy = true);
    try {
      await Repo.teacherRegister(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        kind: 'individual',
        subjects: _subjects.toList(),
        headline: _headline.text.trim().isEmpty ? null : _headline.text.trim(),
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().contains('exists')
                ? 'An account with this email already exists'
                : 'Could not sign up: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter your name';
    if (!_email.text.contains('@')) return 'Please enter a valid email';
    if (_password.text.length < 8) return 'Password must be at least 8 characters';
    if (_subjects.isEmpty) return 'Pick at least one subject you teach';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login')),
        title: Text('Independent Teacher',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teach on Vidyora',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                    'Create your own teacher profile — no school needed. Once you '
                    'sign up you\'re listed for students to find and follow.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                const FieldLabel('Full name'),
                AppInput(controller: _name, hint: 'e.g. Neha Kapoor'),
                const SizedBox(height: 16),
                const FieldLabel('Email'),
                AppInput(controller: _email, hint: 'you@email.com'),
                const SizedBox(height: 16),
                const FieldLabel('Password'),
                AppInput(controller: _password, hint: 'min 8 characters', obscure: true),
                const SizedBox(height: 16),
                const FieldLabel('Subjects you teach'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _allSubjects)
                      _Pick(
                        label: s,
                        selected: _subjects.contains(s),
                        onTap: () => setState(() => _subjects.contains(s)
                            ? _subjects.remove(s)
                            : _subjects.add(s)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const FieldLabel('Headline (optional)'),
                AppInput(
                    controller: _headline,
                    hint: 'e.g. NEET Biology mentor · 8 yrs'),
                const SizedBox(height: 28),
                AppButton(_busy ? 'Creating…' : 'Create my teacher profile',
                    expand: true, onPressed: _busy ? null : _signUp),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                      'You can edit your profile and add exams any time.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  const _Pick(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.18)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border:
                Border.all(color: selected ? AppColors.teal : AppColors.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(12, FontWeight.w600,
                  color: selected ? AppColors.teal : AppColors.muted)),
        ),
      );
}
