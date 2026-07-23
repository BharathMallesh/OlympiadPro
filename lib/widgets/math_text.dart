import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../app/theme.dart';

/// Scraped/AI LaTeX often carries artifacts that KaTeX can't parse inline —
/// most commonly `\\` (a line-break, invalid in inline math) and `\_`
/// (an escaped subscript). Left alone they throw and the segment falls back to
/// showing its raw `$...$` source. Normalising them lets real math render and
/// keeps the fallback readable. Kept deliberately conservative.
String sanitizeInlineTex(String s) {
  var t = s;
  // `\\` is spurious in inline prose (a stray line-break) but is the genuine
  // ROW separator inside array/matrix environments — only collapse it when
  // there's no such environment, or matrices would flatten to a single row.
  if (!t.contains(r'\begin{')) t = t.replaceAll(r'\\', ' ');
  return t
      .replaceAll(r'\_', '_') // escaped subscript -> real subscript
      // `\lim _\limits{...}` / `\sum _\limits{...}`: the scraper split the
      // operator's subscript from `\limits`. KaTeX wants `\limits_{...}`.
      .replaceAll(r'_\limits', r'\limits_')
      // `\left{ ... \right}`: KaTeX requires escaped braces as delimiters.
      .replaceAll(r'\left{', r'\left\{')
      .replaceAll(r'\right}', r'\right\}')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}

/// Human-readable plain-text form for when TeX still won't parse: drop the
/// leftover math punctuation so the option reads as words, never as markup.
String _plainFromTex(String s) => sanitizeInlineTex(s)
    .replaceAll(RegExp(r'[\${}]'), '')
    .replaceAll(RegExp(r'\\[a-zA-Z]+'), '')
    .replaceAll('^', '')
    .trim();

/// Real LaTeX rendering per the Vidyora design doc ("math-latex-white" on
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
      sanitizeInlineTex(latex),
      textStyle: TextStyle(fontSize: fontSize, color: c),
      onErrorFallback: (_) => Text(_plainFromTex(latex),
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

  // `$…$` / `$$…$$` math and `**…**` emphasis are matched in one pass so a bold
  // run can't swallow a `$` (and vice versa).
  static final _segment =
      RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$|\*\*(.+?)\*\*', dotAll: true);

  /// A markdown pipe table. AI-authored solutions carry these, and the
  /// board-paper ingest stores its text with newlines stripped, so rows can't
  /// be recovered from `\n` — the alignment row (`:---`) gives the column
  /// count instead, and cells are chunked by it. Matches a run of pipes only;
  /// prose on either side is rendered normally.
  static final _tableRun = RegExp(r'\|(?:[^|]*\|)+');
  static final _sepCell = RegExp(r'^:?-{2,}:?$');

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: fontSize, color: color, height: 1.5) ??
        TextStyle(fontSize: fontSize, color: color);

    final table = _parseTable(source);
    if (table == null) return _rich(source, base);

    // A table needs block layout, so this branch returns a Column. Everything
    // without a table keeps the original single-Text.rich shape.
    final before = source.substring(0, table.start).trim();
    final after = source.substring(table.end).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (before.isNotEmpty) _rich(before, base),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _table(table, base),
          ),
        ),
        if (after.isNotEmpty) _rich(after, base),
      ],
    );
  }

  Widget _rich(String src, TextStyle base) =>
      Text.rich(TextSpan(style: base, children: _inline(src, base)));

  /// Prose split into text, rendered math, and bold runs. `bold` is set when
  /// recursing into a `**…**` body so emphasis composes with inline math.
  List<InlineSpan> _inline(String src, TextStyle base, {bool bold = false}) {
    final style = bold ? base.copyWith(fontWeight: FontWeight.w700) : base;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _segment.allMatches(src)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: src.substring(cursor, m.start), style: style));
      }
      cursor = m.end;
      if (m.group(3) != null) {
        spans.addAll(_inline(m.group(3)!, base, bold: true));
        continue;
      }
      final rawTex = (m.group(1) ?? m.group(2) ?? '').trim();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          sanitizeInlineTex(rawTex),
          // Inline math must match the surrounding prose colour, or it renders
          // near-white (invisible) on light cards. Fall back to onSurface.
          textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : null,
              color: color ?? base.color ?? AppColors.onSurface),
          // If it still won't parse, show clean text — never the raw `$...$`.
          onErrorFallback: (_) => Text(_plainFromTex(rawTex), style: style),
        ),
      ));
    }
    if (cursor < src.length) {
      spans.add(TextSpan(text: src.substring(cursor), style: style));
    }
    return spans;
  }

  _MarkdownTable? _parseTable(String src) {
    if (!src.contains('|')) return null;
    for (final m in _tableRun.allMatches(src)) {
      // Empty cells are the seams between rows once newlines are gone
      // (`… | | **Ry** | …`), so they carry no data and are dropped.
      final cells = m
          .group(0)!
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      final firstSep = cells.indexWhere(_sepCell.hasMatch);
      if (firstSep <= 0) continue;
      var lastSep = firstSep;
      while (lastSep + 1 < cells.length && _sepCell.hasMatch(cells[lastSep + 1])) {
        lastSep++;
      }
      final cols = lastSep - firstSep + 1;
      final header = cells.sublist(0, firstSep);
      if (header.length != cols) continue; // ragged — not a table we can trust
      final body = cells.sublist(lastSep + 1);
      final rows = <List<String>>[
        for (var i = 0; i + cols <= body.length; i += cols)
          body.sublist(i, i + cols),
      ];
      if (rows.isEmpty) continue;
      return _MarkdownTable(m.start, m.end, header, rows);
    }
    return null;
  }

  Widget _table(_MarkdownTable t, TextStyle base) {
    final line = BorderSide(color: AppColors.outline.withValues(alpha: 0.6));
    Widget cell(String text, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text.rich(TextSpan(
              style: base,
              children: _inline(text, base.copyWith(fontSize: fontSize * 0.95),
                  bold: head))),
        );
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.fromBorderSide(line)),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(horizontalInside: line, verticalInside: line),
        children: [
          TableRow(
            decoration: BoxDecoration(
                color: AppColors.onSurface.withValues(alpha: 0.05)),
            children: [for (final h in t.header) cell(h, head: true)],
          ),
          for (final r in t.rows)
            TableRow(children: [for (final c in r) cell(c)]),
        ],
      ),
    );
  }
}

/// A pipe table recovered from `source`, plus the span it occupied so the
/// prose around it can still render as normal text.
class _MarkdownTable {
  const _MarkdownTable(this.start, this.end, this.header, this.rows);
  final int start;
  final int end;
  final List<String> header;
  final List<List<String>> rows;
}
