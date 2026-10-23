import 'dart:async';

import 'package:flutter/services.dart';

import 'fold_state.dart';

class FoldStateService {
  FoldStateService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('com.duo/fold'),
        _eventChannel =
            eventChannel ?? const EventChannel('com.duo/fold_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<FoldState>? _stream;

  Stream<FoldState> get stream {
    return _stream ??= _buildStream().asBroadcastStream();
  }

  Stream<FoldState> _buildStream() async* {
    // The native handlers register slightly after Dart main() runs, so wait for
    // them before listening or the EventChannel throws MissingPluginException.
    final seed = await _awaitNativeReady();
    if (seed != null) {
      yield seed;
    }

    yield* _eventChannel
        .receiveBroadcastStream()
        .map((event) => FoldState.fromMap(event as Map<dynamic, dynamic>));
  }

  Future<FoldState?> _awaitNativeReady() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      try {
        await start();
        return await getCurrentState();
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    return null;
  }

  Future<FoldState?> getCurrentState() async {
    final result = await _methodChannel
        .invokeMapMethod<dynamic, dynamic>('getCurrentState');
    if (result == null) return null;
    return FoldState.fromMap(result);
  }

  Future<void> start() async {
    await _methodChannel.invokeMethod<bool>('startMonitoring');
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<bool>('stopMonitoring');
    } on MissingPluginException {
      // Nothing registered to stop.
    }
  }
}
