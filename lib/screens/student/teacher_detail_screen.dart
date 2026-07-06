import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Student-facing teacher profile: bio, subjects, classes, average rating and
/// written reviews, plus a rate action once the student has joined.
class TeacherDetailScreen extends StatefulWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});
  final String teacherId;
  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  Map<String, dynamic>? _p;
  List<Map<String, dynamic>> _reviews = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await Repo.teacherProfile(widget.teacherId);
      final r = await Repo.teacherReviews(widget.teacherId);
      if (mounted) setState(() { _p = p; _reviews = r; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not load: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      await Repo.joinTeacher(widget.teacherId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Joined — their exams & practice are now yours'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not join: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRate() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RateSheet(
        teacherId: widget.teacherId,
        initialStars: (_p?['my_stars'] as int?) ?? 0,
        initialReview: (_p?['my_review'] ?? '').toString(),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final joined = p?['joined'] == true;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Teacher', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading || p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsAvatar('${p['full_name']}', size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p['full_name']}',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 3),
                          Text(
                              p['kind'] == 'individual'
                                  ? 'Independent Expert'
                                  : 'Academy · ${p['institution']}',
                              style: AppTheme.mono(11, FontWeight.w600,
                                  color: p['kind'] == 'individual'
                                      ? AppColors.teal
                                      : AppColors.primary)),
                          const SizedBox(height: 8),
                          _Stars(
                              value: (p['rating'] as num?)?.toDouble() ?? 0,
                              count: (p['reviews'] as int?) ?? 0),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((p['headline'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('${p['headline']}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
                if ((p['bio'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${p['bio']}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in ((p['subjects'] as List?) ?? const []).cast<String>())
                      StatusChip(s, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 18),
                if (!joined)
                  AppButton(_busy ? 'Joining…' : 'Join this teacher',
                      expand: true, onPressed: _busy ? null : _join)
                else
                  Row(children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('You follow this teacher',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    AppButton(
                        (p['my_stars'] != null) ? 'Edit rating' : 'Rate',
                        kind: AppBtnKind.secondary,
                        onPressed: _openRate),
                  ]),
                const SizedBox(height: 24),
                Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (_reviews.isEmpty)
                  Text('No written reviews yet.',
                      style: Theme.of(context).textTheme.bodyMedium)
                else
                  for (final r in _reviews) _reviewCard(r),
              ],
            ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${r['student']}',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _Stars(value: (r['stars'] as num).toDouble(), compact: true),
              ]),
              if ((r['review'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('${r['review']}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      );
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.count, this.compact = false});
  final double value;
  final int? count;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 1; i <= 5; i++)
        Icon(i <= value.round() ? Icons.star : Icons.star_border,
            size: compact ? 14 : 18, color: const Color(0xFFE0A93B)),
      if (!compact) ...[
        const SizedBox(width: 6),
        Text(
            value > 0
                ? '${value.toStringAsFixed(1)}  (${count ?? 0})'
                : 'No ratings yet',
            style: AppTheme.mono(11, FontWeight.w600, color: AppColors.muted)),
      ],
    ]);
  }
}

class _RateSheet extends StatefulWidget {
  const _RateSheet(
      {required this.teacherId,
      required this.initialStars,
      required this.initialReview});
  final String teacherId;
  final int initialStars;
  final String initialReview;
  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late int _stars = widget.initialStars;
  late final _review = TextEditingController(text: widget.initialReview);
  bool _saving = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1) return;
    setState(() => _saving = true);
    try {
      await Repo.rateTeacher(widget.teacherId, _stars, _review.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not submit: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate this teacher',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star : Icons.star_border,
                      size: 36, color: const Color(0xFFE0A93B)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppInput(
              controller: _review,
              hint: 'Share what worked for you (optional)',
              maxLines: 3),
          const SizedBox(height: 18),
          AppButton(_saving ? 'Submitting…' : 'Submit rating',
              expand: true, onPressed: _saving || _stars < 1 ? null : _submit),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
