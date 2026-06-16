import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/stores.dart';
import '../../widgets/common.dart';
import 'wizard_shell.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});
  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return WizardScaffold(
      appTitle: 'Create New Exam',
      stepLabel: 'Step 3 of 4 · Scheduling',
      title: 'Scheduling',
      progress: 0.75,
      backRoute: '/wizard/audience',
      nextRoute: '/wizard/upload',
      child: Column(
        children: [
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: wide ? 1 : 0,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Availability Window',
                          icon: Icons.calendar_month_outlined),
                      const SizedBox(height: 18),
                      const FieldLabel('Start Date/Time'),
                      const _DateField('24/10/2024, 09:00 AM'),
                      const SizedBox(height: 16),
                      const FieldLabel('End Date/Time'),
                      const _DateField('24/10/2024, 12:00 PM'),
                    ],
                  ),
                ),
              ),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(
                flex: wide ? 1 : 0,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Time Zone', icon: Icons.schedule_outlined),
                      const SizedBox(height: 18),
                      const FieldLabel('Exam Standard Time'),
                      const _DateField('(UTC+05:30) Chennai, Kolkata, Mumbai'),
                      const SizedBox(height: 12),
                      Text('* All students will see countdowns adjusted to this reference.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Exam Logic', icon: Icons.tune_outlined),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: wide ? 240 : double.infinity,
                      child: _LogicToggle(
                        title: 'Strict Start Time',
                        sub: 'Students must start at the exact minute designated.',
                        value: examDraft.strictStart,
                        onChanged: (v) => setState(() => examDraft.strictStart = v),
                      ),
                    ),
                    SizedBox(
                      width: wide ? 240 : double.infinity,
                      child: _LogicToggle(
                        title: 'Flexible Window',
                        sub: 'Students can start any time between the window.',
                        value: examDraft.flexibleWindow,
                        onChanged: (v) => setState(() => examDraft.flexibleWindow = v),
                      ),
                    ),
                    SizedBox(
                      width: wide ? 240 : double.infinity,
                      child: _LogicToggle(
                        title: 'Grace Period',
                        sub: '10 minutes for technical issues.',
                        value: examDraft.gracePeriod,
                        onChanged: (v) => setState(() => examDraft.gracePeriod = v),
                      ),
                    ),
                    SizedBox(
                      width: wide ? 240 : double.infinity,
                      child: _LogicToggle(
                        title: 'Randomize Question Order',
                        sub: 'Show questions in a different order for each student.',
                        value: examDraft.randomize,
                        onChanged: (v) => setState(() => examDraft.randomize = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(children: [
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.onSurface))),
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.muted),
        ]),
      );
}

class _LogicToggle extends StatelessWidget {
  const _LogicToggle({
    required this.title, required this.sub,
    required this.value, required this.onChanged,
  });
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryStrong,
            onChanged: onChanged,
          ),
        ]),
        const SizedBox(height: 4),
        Text(sub, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
