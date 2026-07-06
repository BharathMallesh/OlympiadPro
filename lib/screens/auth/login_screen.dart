import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/flavor.dart';
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
  // Each app is single-role: the flavor fixes whether this is the student or
  // educator login. (The default lib/main.dart runs the educator flavor.)
  final bool _isStudent = appFlavor.isStudent;
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
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
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
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Image.asset('assets/vidyora-mark.png',
                      fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Text('Vidyora',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('EXCELLENCE IN ACADEMIC COMPETITION',
                    style: AppTheme.mono(11, FontWeight.w500, ls: 1.5)),
                const SizedBox(height: 24),
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
                              : 'educator@vidyora.edu'),
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
                if (!_isStudent)
                  TextButton(
                    onPressed: () => context.go('/register/independent'),
                    child: Text.rich(TextSpan(
                      text: 'Teaching solo?  ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: const [
                        TextSpan(
                            text: 'Sign up as an independent teacher',
                            style: TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600)),
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
