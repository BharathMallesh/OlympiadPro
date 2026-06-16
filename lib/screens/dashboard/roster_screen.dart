import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Class roster backed by the real API: lists every student in the
/// institution with their access code, and adds new students (auto-enrolled
/// into the teacher's first class).
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  List<dynamic> _students = [];
  List<dynamic> _classes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([Repo.students(), Repo.classes()]);
      if (!mounted) return;
      setState(() {
        _students = results[0];
        _classes = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addStudent() async {
    final name = TextEditingController();
    final roll = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Add Student'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const FieldLabel('Full Name'),
          AppInput(controller: name, hint: 'Aarav Patel'),
          const SizedBox(height: 12),
          const FieldLabel('Roll Number'),
          AppInput(controller: roll, hint: '10A01'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty || roll.text.trim().isEmpty) {
      return;
    }
    try {
      final created = await Repo.bulkStudents([
        {'full_name': name.text.trim(), 'roll_no': roll.text.trim()},
      ]);
      // Auto-enroll into the first class so published exams reach them.
      if (_classes.isNotEmpty) {
        await Repo.enroll(_classes.first['id'] as String,
            [created.first['id'] as String]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${name.text.trim()} added · access code ${created.first['access_code']}')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopRedirect(
      fallbackRoute: '/dashboard',
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrGo(context, '/dashboard')),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Class Roster', style: Theme.of(context).textTheme.titleLarge),
              Text(
                  _classes.isEmpty
                      ? 'All students'
                      : (_classes.first['name'] as String? ?? ''),
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
          actions: [
            StatusChip('${_students.length} enrolled', color: AppColors.teal),
            const SizedBox(width: 14),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addStudent,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_alt, color: AppColors.onPrimary),
          label: const Text('Add Student',
              style: TextStyle(color: AppColors.onPrimary)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    AppButton('Retry', onPressed: _load),
                  ]))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            const SectionTitle('Enrolled Students',
                                icon: Icons.groups_outlined),
                            const SizedBox(height: 4),
                            Text(
                                'Students sign in to the app with their roll number '
                                'and the access code below.',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 10),
                            if (_students.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                    child: Text('No students yet.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)),
                              ),
                            for (final s in _students)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StudentCard(
                                    student: s as Map<String, dynamic>),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final name = student['full_name'] as String? ?? '';
    final roll = student['roll_no'] as String? ?? '';
    final code = student['access_code'] as String? ?? '';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        InitialsAvatar(name, size: 40, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(roll, style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Access code $code copied')));
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealStrong.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(code,
                  style:
                      AppTheme.mono(12, FontWeight.w700, color: AppColors.teal)),
              const SizedBox(width: 6),
              const Icon(Icons.copy, size: 12, color: AppColors.teal),
            ]),
          ),
        ),
      ]),
    );
  }
}
