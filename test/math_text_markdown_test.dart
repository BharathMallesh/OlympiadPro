import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympiadpro_teacher/widgets/math_text.dart';

// The exact solution string stored for the "Law of Independent Assortment"
// board question (id f348a511…) — a markdown Punnett table whose newlines the
// board-paper ingest stripped, plus **bold** row headers. Regression guard for
// the MixedMathText markdown fix.
const _independentAssortment =
    "This statement describes Mendel's Law of Independent Assortment. "
    'F2 Generation: (Punnett square showing 16 combinations) '
    '| Gametes | RY | Ry | rY | ry | | :------ | :--- | :--- | :--- | :--- | '
    '| **RY** | RRYY | RRYy | RrYY | RrYy | | **Ry** | RRYy | RRyy | RrYy | Rryy | '
    '| **rY** | RrYY | RrYy | rrYY | rrYy | | **ry** | RrYy | Rryy | rrYy | rryy | '
    'F2 Phenotypic Ratio: 9 (Round Yellow) : 3 (Round Green).';

/// Collect every Text/RichText plain string rendered under [finder]'s tree.
List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final t = (e.widget as Text).data;
    if (t != null) out.add(t);
  }
  for (final e in find.byType(RichText).evaluate()) {
    out.add((e.widget as RichText).text.toPlainText());
  }
  return out;
}

void main() {
  Future<void> pump(WidgetTester tester, String src) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MixedMathText(src)),
          ),
        ),
      );

  testWidgets('markdown Punnett table renders as a Table, not raw pipes',
      (tester) async {
    await pump(tester, _independentAssortment);

    // The pipe table becomes a real Table widget.
    expect(find.byType(Table), findsOneWidget);

    final all = _renderedStrings(tester).join('\n');
    // No raw markdown markup leaks to the reader.
    expect(all.contains('**'), isFalse, reason: 'bold markers must be stripped');
    expect(all.contains('| :---'), isFalse,
        reason: 'alignment row must not render');
    expect(all.contains(':------'), isFalse);

    // Table content survives: header + body cells are present as their own runs.
    expect(find.text('Gametes'), findsOneWidget);
    expect(find.text('RRYY'), findsWidgets);
    // Bold row header rendered as clean text (no asterisks).
    expect(find.text('RY'), findsWidgets);
    // Prose around the table still shows.
    expect(
        find.textContaining('Law of Independent Assortment'), findsOneWidget);
  });

  testWidgets('inline **bold** in prose renders without asterisks',
      (tester) async {
    await pump(tester, 'The **maximum** kinetic energy is proportional.');
    final all = _renderedStrings(tester).join('\n');
    expect(all.contains('**'), isFalse);
    expect(all.contains('maximum'), isTrue);
  });

  testWidgets('plain prose with no markup is unchanged', (tester) async {
    await pump(tester, 'A simple sentence with no markup.');
    expect(find.byType(Table), findsNothing);
    expect(find.text('A simple sentence with no markup.'), findsOneWidget);
  });
}
