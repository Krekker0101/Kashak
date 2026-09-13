import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/app/theme/scetch_theme.dart';
import 'package:scetch/features/tracing/domain/trace_settings.dart';
import 'package:scetch/features/tracing/presentation/grid_painter.dart';
import 'package:scetch/shared/widgets/value_slider.dart';

void main() {
  testWidgets('opacity slider exposes accessible control and changes value', (
    tester,
  ) async {
    var opacity = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ValueSlider(
              label: 'Opacity',
              value: opacity,
              onChanged: (value) => setState(() => opacity = value),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Opacity'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();
    expect(opacity, greaterThan(0.5));
    expect(tester.takeException(), isNull);
  });
  testWidgets('reference grid golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ScetchTheme.create(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('grid'),
              child: SizedBox(
                width: 240,
                height: 320,
                child: ColoredBox(
                  color: const Color(0xFF252B25),
                  child: CustomPaint(
                    painter: GridPainter(const GridSettings(divisions: 4)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const Key('grid')),
      matchesGoldenFile('goldens/reference_grid.png'),
    );
  }, tags: ['golden']);
}
