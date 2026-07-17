import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/api.dart';

/// A diagram attached to a question (circuit, graph, ray diagram …).
///
/// Figures are stored as same-origin paths like `/uploads/figures/x.png`, not
/// absolute URLs: the backend serves them itself, and hard-coding a host in the
/// database would break the moment it moves. Image.network needs an absolute
/// URL though, so the path is resolved against the API base here — the one
/// place that knows where the backend lives. Absolute URLs (a CDN, say) are
/// passed through untouched.
class QuestionFigure extends StatelessWidget {
  const QuestionFigure(this.url, {super.key});

  final String url;

  String get _resolved =>
      url.startsWith('http') ? url : '${ApiClient.baseUrl}$url';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          // A white plate behind the figure: diagrams are drawn on white, and
          // on the dark theme a transparent PNG would otherwise lose its axes.
          color: Colors.white,
          width: double.infinity,
          child: Image.network(
            _resolved,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 160,
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
            // Say so when the diagram is missing. Hiding the failure silently
            // leaves the student staring at a question that can't be answered
            // with no idea why — better to admit the figure didn't load.
            errorBuilder: (_, _, _) => Container(
              height: 96,
              color: AppColors.surfaceContainer,
              padding: const EdgeInsets.all(12),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 18, color: AppColors.muted),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "This question's diagram could not be loaded.",
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
