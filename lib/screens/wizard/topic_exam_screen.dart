import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

/// Quick exam builder: a teacher picks topics (chapters) from the question
/// bank, chooses how many questions per topic, assigns the exam to one or more
/// classes, and publishes — all in one screen. Ideal for a focused daily test
/// or a remedial exam on a topic the class is weak in.
class TopicExamScreen extends StatefulWidget {
  const TopicExamScreen({super.key});
  @override
  State<TopicExamScreen> createState() => _TopicExamScreenState();
}

class _TopicExamScreenState extends State<TopicExamScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<Map<String, dynamic>> _topics = const [];
  List<Map<String, dynamic>> _classes = const [];

  final _title = TextEditingController();
  final Map<String, int> _counts = {}; // "subjecttopic" -> count
  final Set<String> _classIds = {};
  String _filter = '';
  int _duration = 30;

  static const _subjectIcons = {
    'Math': Icons.functions,
    'Maths': Icons.functions,
    'Mathematics': Icons.functions,
    'Physics': Icons.bolt,
    'Chemistry': Icons.science_outlined,
    'Biology': Icons.biotech_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Future.wait([Repo.examTopics(), Repo.classes()]);
      if (!mounted) return;
      setState(() {
        _topics = res[0].cast<Map<String, dynamic>>();
        _classes = res[1].cast<Map<String, dynamic>>();
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

  String _key(String subject, String topic) => '$subject$topic';
  int get _total => _counts.values.fold(0, (a, b) => a + b);

  void _bump(String key, int available, int delta) {
    setState(() {
      final next = ((_counts[key] ?? 0) + delta).clamp(0, available);
      if (next == 0) {
        _counts.remove(key);
      } else {
        _counts[key] = next;
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final q = _filter.trim().toLowerCase();
    final out = <String, List<Map<String, dynamic>>>{};
    for (final t in _topics) {
      final subject = t['subject'] as String? ?? 'General';
      final topic = t['topic'] as String? ?? 'General';
      if (q.isNotEmpty &&
          !topic.toLowerCase().contains(q) &&
          !subject.toLowerCase().contains(q)) {
        continue;
      }
      (out[subject] ??= []).add(t);
    }
    return out;
  }

  Future<void> _create({required bool publish}) async {
    if (_total == 0) return;
    if (publish && _classIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pick at least one class to publish to.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final items = [
        for (final e in _counts.entries)
          {
            'subject': e.key.split('').first,
            'topic': e.key.split('').last,
            'count': e.value,
          }
      ];
      final title = _title.text.trim().isEmpty
          ? _autoTitle()
          : _title.text.trim();
      await Repo.createTopicExam(
        title: title,
        durationMin: _duration,
        classIds: _classIds.toList(),
        items: items,
        publish: publish,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(publish
              ? 'Published "$title" to ${_classIds.length} class(es).'
              : 'Saved "$title" as a draft.'),
          backgroundColor: AppColors.success));
      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _autoTitle() {
    final subjects = _counts.keys
        .map((k) => k.split('').first)
        .toSet()
        .join(', ');
    return '$subjects Topic Test';
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
          title: Text('Topic Exam',
              style: Theme.of(context).textTheme.titleLarge),
          actions: [
            if (_total > 0)
              StatusChip('$_total questions', color: AppColors.teal),
            const SizedBox(width: 14),
          ],
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
                : _body(context),
        bottomNavigationBar: _loading || _error != null
            ? null
            : _bottomBar(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
              'No questions in your bank yet. Upload a paper or add questions, '
              'then build a topic exam.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    final grouped = _grouped;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SectionTitle('Exam Details', icon: Icons.description_outlined),
        const SizedBox(height: 10),
        const FieldLabel('Title (optional — auto-named from topics)'),
        AppInput(controller: _title, hint: 'e.g. Calculus — Daily Drill'),
        const SizedBox(height: 14),
        const FieldLabel('Duration'),
        Wrap(spacing: 8, children: [
          for (final m in [15, 30, 45, 60, 90])
            _chip('$m min', _duration == m,
                () => setState(() => _duration = m)),
        ]),
        const SizedBox(height: 20),

        const SectionTitle('Assign to Classes', icon: Icons.groups_outlined),
        const SizedBox(height: 10),
        if (_classes.isEmpty)
          Text('No classes yet — create one in the roster to publish.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in _classes)
              _chip(
                  '${c['name']}'
                  '${c['section'] != null && '${c['section']}'.isNotEmpty ? ' · ${c['section']}' : ''}',
                  _classIds.contains(c['id']),
                  () => setState(() {
                        final id = c['id'] as String;
                        _classIds.contains(id)
                            ? _classIds.remove(id)
                            : _classIds.add(id);
                      }),
                  color: AppColors.secondary),
          ]),
        const SizedBox(height: 20),

        const SectionTitle('Pick Topics', icon: Icons.account_tree_outlined),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _filter = v),
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search topics…',
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        ),
        const SizedBox(height: 14),
        if (grouped.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: Text('No topics match "$_filter".',
                    style: Theme.of(context).textTheme.bodyMedium)),
          )
        else
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(children: [
                Icon(_subjectIcons[entry.key] ?? Icons.menu_book_outlined,
                    size: 15, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(entry.key.toUpperCase(),
                    style: AppTheme.mono(11, FontWeight.w700,
                        color: AppColors.teal, ls: 1)),
                const SizedBox(width: 8),
                Text('${entry.value.length} topics',
                    style: AppTheme.mono(9, FontWeight.w500)),
              ]),
            ),
            for (final t in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _topicRow(context, t),
              ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _topicRow(BuildContext context, Map<String, dynamic> t) {
    final subject = t['subject'] as String? ?? 'General';
    final topic = t['topic'] as String? ?? 'General';
    final available = (t['available'] as num?)?.toInt() ?? 0;
    final key = _key(subject, topic);
    final count = _counts[key] ?? 0;
    final active = count > 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: active ? AppColors.onSurface : null)),
              const SizedBox(height: 2),
              Text('$available available',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _stepBtn(Icons.remove, count > 0, () => _bump(key, available, -1)),
        SizedBox(
          width: 40,
          child: Text('$count',
              textAlign: TextAlign.center,
              style: AppTheme.mono(16, FontWeight.w700,
                  color: active ? AppColors.teal : AppColors.muted)),
        ),
        _stepBtn(Icons.add, count < available, () => _bump(key, available, 1)),
      ]),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Expanded(
            child: AppButton(
                _submitting ? 'Saving…' : 'Save Draft',
                kind: AppBtnKind.ghost,
                onPressed: _total == 0 || _submitting
                    ? null
                    : () => _create(publish: false)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: AppButton(
                _total == 0
                    ? 'Select topics'
                    : _submitting
                        ? 'Publishing…'
                        : 'Publish · $_total Qs',
                trailingIcon: Icons.send,
                onPressed: _total == 0 || _submitting
                    ? null
                    : () => _create(publish: true)),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
          {Color color = AppColors.primary}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : AppColors.scaffold,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: selected ? color : AppColors.outlineStrong),
          ),
          child: Text(label,
              style: AppTheme.mono(11, FontWeight.w600,
                  color: selected ? color : AppColors.muted)),
        ),
      );

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: enabled ? AppColors.outlineStrong : AppColors.outline),
          ),
          child: Icon(icon,
              size: 16,
              color: enabled ? AppColors.onSurface : AppColors.muted),
        ),
      );
}
