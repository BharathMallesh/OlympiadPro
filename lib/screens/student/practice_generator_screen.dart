import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'student_shell.dart';

/// Builds a practice set from the question bank. The student can either pick a
/// number of questions per *subject*, or drill into specific *topics*
/// (chapters) — e.g. to revise exactly what was taught that day, or to focus a
/// quick exam on a topic they're weak in.
class PracticeGeneratorScreen extends StatefulWidget {
  const PracticeGeneratorScreen({super.key});
  @override
  State<PracticeGeneratorScreen> createState() => _PracticeGeneratorScreenState();
}

class _PracticeGeneratorScreenState extends State<PracticeGeneratorScreen> {
  bool _loading = true;
  bool _generating = false;
  String? _error;

  /// 'subject' or 'topic'.
  String _mode = 'subject';

  List<Map<String, dynamic>> _subjects = const [];
  final Map<String, int> _counts = {}; // subject -> count

  bool _topicsLoaded = false;
  List<Map<String, dynamic>> _topics = const [];
  final Map<String, int> _topicCounts = {}; // "subjecttopic" -> count
  String _filter = '';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Repo.practiceSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = rows.cast<Map<String, dynamic>>();
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

  Future<void> _loadTopics() async {
    if (_topicsLoaded) return;
    try {
      final rows = await Repo.practiceTopics();
      if (!mounted) return;
      setState(() {
        _topics = rows.cast<Map<String, dynamic>>();
        _topicsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String _key(String subject, String topic) => '$subject$topic';

  int get _total => _mode == 'subject'
      ? _counts.values.fold(0, (a, b) => a + b)
      : _topicCounts.values.fold(0, (a, b) => a + b);

  void _bump(Map<String, int> store, String key, int available, int delta) {
    setState(() {
      final next = ((store[key] ?? 0) + delta).clamp(0, available);
      if (next == 0) {
        store.remove(key);
      } else {
        store[key] = next;
      }
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final items = _mode == 'subject'
          ? [
              for (final e in _counts.entries)
                {'subject': e.key, 'count': e.value}
            ]
          : [
              for (final e in _topicCounts.entries)
                {
                  'subject': e.key.split('').first,
                  'topic': e.key.split('').last,
                  'count': e.value,
                }
            ];
      final res = await Repo.practiceGenerate(items);
      if (!mounted) return;
      context.push('/student/practice-session',
          extra: (res['questions'] as List<dynamic>));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Topics grouped by subject, filtered by the search box.
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

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      title: 'Vidyora',
      currentTab: 1,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  AppButton('Retry', onPressed: _load),
                ]))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Student Hub  /  AI Practice',
                                style:
                                    AppTheme.mono(10, FontWeight.w500, ls: 0.5)),
                            const SizedBox(height: 8),
                            Text('Build Your Practice Set',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Text(
                                _mode == 'subject'
                                    ? 'Pick how many questions you want from each '
                                        'subject — drawn at random from your '
                                        'question bank.'
                                    : 'Drill into a topic (chapter) to revise what '
                                        'you were taught, or focus on a topic '
                                        "you're weak in.",
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 16),
                            _modeToggle(context),
                            const SizedBox(height: 16),
                            if (_mode == 'subject')
                              ..._subjectBody(context)
                            else
                              ..._topicBody(context),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: AppButton(
                          _total == 0
                              ? 'Select questions to begin'
                              : _generating
                                  ? 'Generating…'
                                  : 'Generate & Start · $_total questions',
                          expand: true,
                          trailingIcon: Icons.play_arrow,
                          onPressed: _total == 0 || _generating
                              ? null
                              : _generate),
                    ),
                  ],
                ),
    );
  }

  Widget _modeToggle(BuildContext context) {
    Widget tab(String value, String label, IconData icon) {
      final active = _mode == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            setState(() => _mode = value);
            if (value == 'topic') _loadTopics();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: active ? AppColors.primary : AppColors.outline),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16,
                  color: active ? AppColors.primary : AppColors.muted),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTheme.mono(11, FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.muted)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      tab('subject', 'BY SUBJECT', Icons.category_outlined),
      const SizedBox(width: 10),
      tab('topic', 'BY TOPIC', Icons.account_tree_outlined),
    ]);
  }

  // ---- Subject mode ----

  List<Widget> _subjectBody(BuildContext context) {
    if (_subjects.isEmpty) {
      return [_emptyBank(context)];
    }
    return [
      for (final s in _subjects)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _subjectRow(context, s),
        ),
    ];
  }

  Widget _subjectRow(BuildContext context, Map<String, dynamic> s) {
    final subject = s['subject'] as String? ?? '';
    final available = (s['available'] as num?)?.toInt() ?? 0;
    final count = _counts[subject] ?? 0;
    final active = count > 0;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (active ? AppColors.primary : AppColors.muted)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(_subjectIcons[subject] ?? Icons.menu_book_outlined,
              size: 18, color: active ? AppColors.primary : AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: Theme.of(context).textTheme.titleMedium),
              Text('$available available',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
        ),
        _stepper(count, available, (d) => _bump(_counts, subject, available, d)),
      ]),
    );
  }

  // ---- Topic mode ----

  List<Widget> _topicBody(BuildContext context) {
    if (!_topicsLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      ];
    }
    if (_topics.isEmpty) {
      return [_emptyBank(context)];
    }
    final grouped = _grouped;
    return [
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
      const SizedBox(height: 16),
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
    ];
  }

  Widget _topicRow(BuildContext context, Map<String, dynamic> t) {
    final subject = t['subject'] as String? ?? 'General';
    final topic = t['topic'] as String? ?? 'General';
    final available = (t['available'] as num?)?.toInt() ?? 0;
    final key = _key(subject, topic);
    final count = _topicCounts[key] ?? 0;
    final active = count > 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                          fontSize: 14,
                          color: active ? AppColors.onSurface : null)),
              const SizedBox(height: 2),
              Text('$available available',
                  style: AppTheme.mono(9, FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _stepper(
            count, available, (d) => _bump(_topicCounts, key, available, d)),
      ]),
    );
  }

  // ---- Shared bits ----

  Widget _stepper(int count, int available, void Function(int) onDelta) {
    final active = count > 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _stepBtn(Icons.remove, count > 0, () => onDelta(-1)),
      SizedBox(
        width: 40,
        child: Text('$count',
            textAlign: TextAlign.center,
            style: AppTheme.mono(16, FontWeight.w700,
                color: active ? AppColors.teal : AppColors.muted)),
      ),
      _stepBtn(Icons.add, count < available, () => onDelta(1)),
    ]);
  }

  Widget _emptyBank(BuildContext context) => AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: Text(
                  'No practice questions available yet. Ask your teacher to '
                  'add questions to the bank.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium)),
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
