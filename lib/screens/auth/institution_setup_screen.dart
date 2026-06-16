import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/drafts.dart';
import '../../widgets/common.dart';

class InstitutionSetupScreen extends StatefulWidget {
  const InstitutionSetupScreen({super.key});
  @override
  State<InstitutionSetupScreen> createState() => _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState extends State<InstitutionSetupScreen> {
  String? _selectedInstitute;
  late final _institution =
      TextEditingController(text: onboardingDraft.institutionName);
  late final _className = TextEditingController(text: onboardingDraft.className);
  late final _grade = TextEditingController(text: onboardingDraft.grade);
  late final _section = TextEditingController(text: onboardingDraft.section);

  void _continue() {
    final institution = _selectedInstitute ?? _institution.text.trim();
    if (institution.isEmpty || _className.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Institution and class name are required'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    onboardingDraft
      ..institutionName = institution
      ..className = _className.text.trim()
      ..grade = _grade.text.trim()
      ..section = _section.text.trim();
    context.go('/register/finalize');
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/register',
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/register')),
        title: Text('Teacher Onboarding',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary)),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Help')),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 02 OF 03',
                    style: AppTheme.mono(12, FontWeight.w600,
                        color: AppColors.primary, ls: 1.5)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('Link Institution &\nSetup Class',
                          style: Theme.of(context).textTheme.headlineLarge),
                    ),
                    Text('66%\nComplete',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 14),
                const ProgressLine(0.66, height: 5),
                const SizedBox(height: 24),

                // Institution selection
                AppCard(
                  accentTop: AppColors.success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Institution Selection',
                          icon: Icons.account_balance_outlined),
                      const SizedBox(height: 16),
                      const FieldLabel('Institution Name'),
                      AppInput(
                          controller: _institution,
                          icon: Icons.account_balance_outlined,
                          hint: 'e.g., Excellence Academy'),
                      const SizedBox(height: 14),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final name in ['Excellence Academy', 'IIT-JEE Center'])
                          _InstituteChip(
                            name: name,
                            selected: _selectedInstitute == name,
                            onTap: () => setState(() => _selectedInstitute = name),
                          ),
                        _AddNewChip(),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Class creation
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Class Creation', icon: Icons.groups_outlined),
                      const SizedBox(height: 16),
                      const FieldLabel('Class Name'),
                      AppInput(
                          controller: _className,
                          hint: 'Physics Advanced - Sec B'),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Grade'),
                              AppInput(controller: _grade, hint: 'Grade 12'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Section'),
                              AppInput(controller: _section, hint: 'B'),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  AppButton('Back',
                      kind: AppBtnKind.ghost,
                      icon: Icons.arrow_back,
                      onPressed: () => context.go('/register')),
                  const Spacer(),
                  AppButton('Continue',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _continue),
                ]),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _InstituteChip extends StatelessWidget {
  const _InstituteChip(
      {required this.name, required this.selected, required this.onTap});
  final String name;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryStrong.withValues(alpha: 0.18)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? Icons.check_circle : Icons.history,
              size: 15, color: selected ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 8),
          Text(name,
              style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.onSurface,
                  fontSize: 13)),
        ]),
      ),
    );
  }
}

class _AddNewChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.add_circle_outline, size: 15, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Add New',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
        ]),
      );
}
