import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common.dart';

/// Teacher-facing: edit the public marketplace profile students see in the
/// "Find a Teacher" directory, and toggle whether you're listed at all.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  static const _allSubjects = ['Physics', 'Chemistry', 'Mathematics', 'Biology'];
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final Set<String> _subjects = {};
  bool _isPublic = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await Repo.teacherProfileSelf();
      if (!mounted) return;
      setState(() {
        _headline.text = (p['headline'] ?? '').toString();
        _bio.text = (p['bio'] ?? '').toString();
        _subjects
          ..clear()
          ..addAll(((p['subjects'] as List?) ?? const []).cast<String>());
        _isPublic = p['is_public'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not load profile: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Repo.updateTeacherProfile({
        'headline': _headline.text.trim(),
        'bio': _bio.text.trim(),
        'subjects': _subjects.toList(),
        'is_public': _isPublic,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isPublic
              ? 'Saved — you are now listed in the student directory'
              : 'Saved — you are hidden from the directory'),
          backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not save: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Public Profile',
      currentRoute: '/public-profile',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        accentTop: AppColors.teal,
                        child: Row(children: [
                          const Icon(Icons.storefront_outlined,
                              color: AppColors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('List me in the student directory',
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                    'When on, students can find and follow you from "Find a Teacher".',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublic,
                            activeThumbColor: AppColors.teal,
                            onChanged: (v) => setState(() => _isPublic = v),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      const FieldLabel('Headline'),
                      AppInput(
                          controller: _headline,
                          hint: 'e.g. IIT-JEE Physics mentor · 10 yrs'),
                      const SizedBox(height: 16),
                      const FieldLabel('About you'),
                      AppInput(
                          controller: _bio,
                          hint: 'Your experience, teaching style, results…',
                          maxLines: 4),
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 28),
                      AppButton(_saving ? 'Saving…' : 'Save Profile',
                          expand: true,
                          onPressed: _saving ? null : _save),
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
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(12, FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.muted)),
        ),
      );
}
