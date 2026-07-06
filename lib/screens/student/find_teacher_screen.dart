import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Marketplace directory: students browse public teachers (independent experts
/// and academy teachers), filter by subject, and follow one to get its exams
/// and practice.
class FindTeacherScreen extends StatefulWidget {
  const FindTeacherScreen({super.key});
  @override
  State<FindTeacherScreen> createState() => _FindTeacherScreenState();
}

class _FindTeacherScreenState extends State<FindTeacherScreen> {
  static const _subjects = ['All', 'Physics', 'Chemistry', 'Mathematics', 'Biology'];
  String _subject = 'All';
  final _search = TextEditingController();
  List<Map<String, dynamic>> _teachers = const [];
  bool _loading = true;
  String? _joiningId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await Repo.teacherDirectory(
          subject: _subject == 'All' ? null : _subject, q: _search.text);
      if (mounted) setState(() => _teachers = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not load teachers: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(Map<String, dynamic> t) async {
    setState(() => _joiningId = '${t['id']}');
    try {
      await Repo.joinTeacher('${t['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Joined ${t['full_name']} — their exams & practice are now yours'),
          backgroundColor: AppColors.success));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not join: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  /// Client-side text filter over the loaded list (subject is server-side).
  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _teachers;
    return _teachers.where((t) {
      final hay = '${t['full_name']} ${t['headline'] ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Find a Teacher',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInput(
                  controller: _search,
                  hint: 'Search by name or expertise…',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final s in _subjects)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _SubjectChip(
                            label: s,
                            selected: _subject == s,
                            onTap: () {
                              setState(() => _subject = s);
                              _load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No teachers found.',
                            style: Theme.of(context).textTheme.bodyMedium))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> t) {
    final individual = t['kind'] == 'individual';
    final subjects = ((t['subjects'] as List?) ?? const []).cast<String>();
    final rating = t['rating'];
    final joining = _joiningId == '${t['id']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar('${t['full_name']}', size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t['full_name']}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                          individual
                              ? 'Independent Expert'
                              : 'Academy · ${t['institution']}',
                          style: AppTheme.mono(10, FontWeight.w600,
                              color: individual ? AppColors.teal : AppColors.primary)),
                    ],
                  ),
                ),
                if (rating != null)
                  Row(children: [
                    const Icon(Icons.star, size: 15, color: Color(0xFFE0A93B)),
                    const SizedBox(width: 3),
                    Text((rating as num).toStringAsFixed(1),
                        style: AppTheme.mono(12, FontWeight.w700)),
                  ]),
              ],
            ),
            if ((t['headline'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${t['headline']}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in subjects)
                  StatusChip(s, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.groups_outlined, size: 15, color: AppColors.muted),
              const SizedBox(width: 5),
              Text('${t['students']} student${t['students'] == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              AppButton(joining ? 'Joining…' : 'Join',
                  onPressed: joining ? null : () => _join(t)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(11, FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.muted)),
        ),
      );
}
