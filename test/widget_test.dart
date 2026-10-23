// Validates the Dart-side fold-state parsing and that the UI renders the
// stage reported by a (faked) native event stream.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo/fold_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoldState.fromMap', () {
    test('parses a well-formed payload', () {
      final state = FoldState.fromMap({
        'stage': 'half_open',
        'hingeAngle': 92.5,
        'orientation': 'landscape',
        'timestamp': 1700000000000,
      });

      expect(state.stage, FoldStage.halfOpen);
      expect(state.hingeAngle, 92.5);
      expect(state.orientation, ScreenOrientation.landscape);
      expect(state.timestamp.millisecondsSinceEpoch, 1700000000000);
    });

    test('falls back gracefully on missing/invalid fields', () {
      final state = FoldState.fromMap(<dynamic, dynamic>{});

      expect(state.stage, FoldStage.unknown);
      expect(state.hingeAngle, 0);
      expect(state.orientation, ScreenOrientation.unknown);
    });

    test('maps every known stage string', () {
      expect(FoldStage.fromRaw('closed'), FoldStage.closed);
      expect(FoldStage.fromRaw('half_open'), FoldStage.halfOpen);
      expect(FoldStage.fromRaw('fully_open'), FoldStage.fullyOpen);
      expect(FoldStage.fromRaw('garbage'), FoldStage.unknown);
    });
  });

  testWidgets('UI renders the stage carried by a fold-state event',
      (WidgetTester tester) async {
    final controller = StreamController<Map<dynamic, dynamic>>();
    addTearDown(controller.close);

    // Drive the same decode -> render path the app uses, but feed it from a
    // controller the test owns so the EventChannel transport is not involved.
    await tester.pumpWidget(
      MaterialApp(
        home: StreamBuilder<FoldState>(
          stream: controller.stream.map(FoldState.fromMap),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('waiting');
            }
            return Text(snapshot.data!.stage.label);
          },
        ),
      ),
    );

    expect(find.text('waiting'), findsOneWidget);

    controller.add({
      'stage': 'fully_open',
      'hingeAngle': 170.0,
      'orientation': 'portrait',
      'timestamp': 1700000000000,
    });
    await tester.pump();

    expect(find.text('Fully Open'), findsOneWidget);
  });
}
