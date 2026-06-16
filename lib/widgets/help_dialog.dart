import 'package:flutter/material.dart';
import '../app/theme.dart';

/// An app-bar Help action that opens a contextual help sheet. Pass the
/// screen-specific [title] and a list of (heading, body) tips.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.title, required this.tips});
  final String title;
  final List<(String, String)> tips;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showHelpSheet(context, title: title, tips: tips),
      icon: const Icon(Icons.help_outline, size: 18),
      label: const Text('Help'),
    );
  }
}

/// Shows the help content as a bottom sheet (works well on phone and web).
Future<void> showHelpSheet(
  BuildContext context, {
  required String title,
  required List<(String, String)> tips,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.help_outline,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ]),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (heading, body) in tips) ...[
                        Text(heading,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(body,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
