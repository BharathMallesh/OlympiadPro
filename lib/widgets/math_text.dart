import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../app/theme.dart';

/// Real LaTeX rendering per the MathKraft design doc ("math-latex-white" on
/// the void panel, >=7:1 contrast). Falls back to monospace if TeX parsing
/// fails so malformed AI output never breaks a screen.
class MathText extends StatelessWidget {
  const MathText(this.latex, {super.key, this.fontSize = 16, this.color});
  final String latex;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFF5F5F5);
    return Math.tex(
      latex,
      textStyle: TextStyle(fontSize: fontSize, color: c),
      onErrorFallback: (_) => Text(latex,
          style: AppTheme.mono(fontSize * 0.85, FontWeight.w500, color: c, ls: 0)),
    );
  }
}

/// The standard "void panel" container: pitch-black surface holding rendered
/// math, used across exam, review, and solution screens.
class MathPanel extends StatelessWidget {
  const MathPanel(this.latex,
      {super.key, this.fontSize = 16, this.color, this.center = false});
  final String latex;
  final double fontSize;
  final Color? color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Align(
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: MathText(latex, fontSize: fontSize, color: color),
        ),
      ),
    );
  }
}

/// Mixed prose + inline LaTeX: plain text renders as normal text, anything
/// inside $...$ (or $$...$$) renders through KaTeX. AI-imported prompts are
/// usually this shape ("Find $f'(x)$ when ...").
class MixedMathText extends StatelessWidget {
  const MixedMathText(this.source,
      {super.key, this.fontSize = 15, this.color, this.style});
  final String source;
  final double fontSize;
  final Color? color;
  final TextStyle? style;

  static final _mathSegment = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: fontSize, color: color, height: 1.5) ??
        TextStyle(fontSize: fontSize, color: color);
    if (!source.contains(r'$')) return Text(source, style: base);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _mathSegment.allMatches(source)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, m.start)));
      }
      final tex = (m.group(1) ?? m.group(2) ?? '').trim();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          tex,
          textStyle: TextStyle(
              fontSize: fontSize, color: color ?? const Color(0xFFF5F5F5)),
          onErrorFallback: (_) => Text('\$$tex\$', style: base),
        ),
      ));
      cursor = m.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
