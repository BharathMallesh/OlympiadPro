import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/login')),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _sent ? _confirmation(context) : _form(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryStrong.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Reset your password',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              "Enter the email associated with your account and we'll send a "
              'secure reset link.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          const FieldLabel('Email Address'),
          AppInput(
              controller: _email,
              icon: Icons.mail_outline,
              hint: 'you@university.edu'),
          const SizedBox(height: 24),
          AppButton('Send Reset Link',
              expand: true,
              trailingIcon: Icons.send_outlined,
              onPressed: () => setState(() => _sent = true)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
                onPressed: () => popOrGo(context, '/login'),
                child: const Text('Back to Sign In')),
          ),
        ],
      );

  Widget _confirmation(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppColors.onSuccess, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Check your inbox',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              'If an account exists for '
              '${_email.text.isEmpty ? 'that address' : _email.text}, a reset '
              'link is on its way. It expires in 30 minutes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          AppButton('Back to Sign In',
              expand: true, onPressed: () => context.go('/login')),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () => setState(() => _sent = false),
              child: const Text('Use a different email')),
        ],
      );
}
