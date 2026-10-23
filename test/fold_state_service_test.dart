// Verifies the FoldStateService tolerates the startup race where native
// channel handlers are not yet registered (MissingPluginException).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo/fold_state.dart';
import 'package:duo/fold_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('com.duo/fold');
  final messenger =
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
  });

  test('getCurrentState decodes the native snapshot', () async {
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      expect(call.method, 'getCurrentState');
      return {
        'stage': 'closed',
        'hingeAngle': 10.0,
        'orientation': 'portrait',
        'timestamp': 1700000000000,
      };
    });

    final service = FoldStateService();
    final state = await service.getCurrentState();

    expect(state, isNotNull);
    expect(state!.stage, FoldStage.closed);
    expect(state.hingeAngle, 10.0);
  });

  test('stream retries past an early MissingPluginException', () async {
    var startCalls = 0;

    // Simulate the native handler being absent for the first two
    // startMonitoring calls, then coming online.
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      switch (call.method) {
        case 'startMonitoring':
          startCalls++;
          if (startCalls < 3) {
            throw MissingPluginException('not ready yet');
          }
          return true;
        case 'getCurrentState':
          return {
            'stage': 'fully_open',
            'hingeAngle': 175.0,
            'orientation': 'landscape',
            'timestamp': 1700000000000,
          };
        default:
          return null;
      }
    });

    final service = FoldStateService();

    // The resilient stream should wait out the failures and then emit the
    // seeded snapshot without surfacing the MissingPluginException.
    final first = await service.stream.first.timeout(
      const Duration(seconds: 5),
    );

    expect(startCalls, greaterThanOrEqualTo(3));
    expect(first.stage, FoldStage.fullyOpen);
    expect(first.hingeAngle, 175.0);
  });

  test('stop swallows MissingPluginException', () async {
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      throw MissingPluginException('no handler');
    });

    final service = FoldStateService();
    // Should complete without throwing.
    await service.stop();
  });
}
