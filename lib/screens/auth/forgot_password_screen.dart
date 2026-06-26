import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Self-service password reset for students: enter email → receive a 6-digit
/// code by email → enter the code + a new password. Three stages tracked by
/// [_stage]: 0 = request, 1 = enter code + new password, 2 = done.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  int _stage = 0;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Repo.studentForgotPassword(email);
      if (mounted) setState(() => _stage = 1);
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final code = _code.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the code from your email.');
      return;
    }
    if (_pw.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (_pw.text != _pw2.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Repo.studentResetPassword(_email.text.trim(), code, _pw.text);
      if (mounted) setState(() => _stage = 2);
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();

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
              onPressed: () {
                // From the code stage, step back to the email stage.
                if (_stage == 1) {
                  setState(() {
                    _stage = 0;
                    _error = null;
                  });
                } else {
                  popOrGo(context, '/login');
                }
              }),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: switch (_stage) {
                0 => _requestForm(context),
                1 => _resetForm(context),
                _ => _done(context),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13))),
            ]),
          ),
        );

  // Stage 0 — ask for the email.
  Widget _requestForm(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(Icons.lock_reset),
          const SizedBox(height: 20),
          Text('Reset your password',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              "Enter the email associated with your account and we'll send a "
              '6-digit reset code.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _errorBox(),
          const FieldLabel('Email Address'),
          AppInput(
              controller: _email,
              icon: Icons.mail_outline,
              hint: 'you@example.com'),
          const SizedBox(height: 24),
          AppButton(_busy ? 'Sending…' : 'Send Reset Code',
              expand: true,
              trailingIcon: Icons.send_outlined,
              onPressed: _busy ? null : _sendCode),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
                onPressed: () => popOrGo(context, '/login'),
                child: const Text('Back to Sign In')),
          ),
        ],
      );

  // Stage 1 — enter the code + the new password.
  Widget _resetForm(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(Icons.mark_email_read_outlined),
          const SizedBox(height: 20),
          Text('Enter your code',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              'If an account exists for '
              '${_email.text.trim().isEmpty ? 'that address' : _email.text.trim()}, '
              "we've sent a 6-digit code. It expires in 15 minutes.",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _errorBox(),
          const FieldLabel('Reset Code'),
          AppInput(
              controller: _code,
              icon: Icons.pin_outlined,
              hint: '6-digit code'),
          const SizedBox(height: 16),
          const FieldLabel('New Password'),
          AppInput(
              controller: _pw,
              icon: Icons.lock_outline,
              obscure: _obscure,
              hint: 'At least 8 characters',
              suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18, color: AppColors.muted),
                  onPressed: () => setState(() => _obscure = !_obscure))),
          const SizedBox(height: 16),
          const FieldLabel('Confirm New Password'),
          AppInput(
              controller: _pw2,
              icon: Icons.lock_outline,
              obscure: _obscure,
              hint: 'Re-enter password'),
          const SizedBox(height: 24),
          AppButton(_busy ? 'Updating…' : 'Reset Password',
              expand: true,
              trailingIcon: Icons.check,
              onPressed: _busy ? null : _reset),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
                onPressed: _busy ? null : _sendCode,
                child: const Text('Resend code')),
          ),
        ],
      );

  // Stage 2 — success.
  Widget _done(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppColors.onSuccess, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Password updated',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('You can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          AppButton('Back to Sign In',
              expand: true, onPressed: () => context.go('/login')),
        ],
      );

  Widget _icon(IconData icon) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryStrong.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Icon(icon, color: AppColors.primary, size: 30),
      );
}
