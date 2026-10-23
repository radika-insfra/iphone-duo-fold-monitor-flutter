import 'package:flutter/foundation.dart';

enum FoldStage {
  closed,
  halfOpen,
  fullyOpen,
  unknown;

  static FoldStage fromRaw(String? raw) {
    switch (raw) {
      case 'closed':
        return FoldStage.closed;
      case 'half_open':
        return FoldStage.halfOpen;
      case 'fully_open':
        return FoldStage.fullyOpen;
      default:
        return FoldStage.unknown;
    }
  }

  String get label {
    switch (this) {
      case FoldStage.closed:
        return 'Closed';
      case FoldStage.halfOpen:
        return 'Half-Open';
      case FoldStage.fullyOpen:
        return 'Fully Open';
      case FoldStage.unknown:
        return 'Unknown';
    }
  }
}

enum ScreenOrientation {
  portrait,
  landscape,
  unknown;

  static ScreenOrientation fromRaw(String? raw) {
    switch (raw) {
      case 'portrait':
        return ScreenOrientation.portrait;
      case 'landscape':
        return ScreenOrientation.landscape;
      default:
        return ScreenOrientation.unknown;
    }
  }

  String get label {
    switch (this) {
      case ScreenOrientation.portrait:
        return 'Portrait';
      case ScreenOrientation.landscape:
        return 'Landscape';
      case ScreenOrientation.unknown:
        return 'Unknown';
    }
  }
}

@immutable
class FoldState {
  const FoldState({
    required this.stage,
    required this.hingeAngle,
    required this.orientation,
    required this.timestamp,
  });

  final FoldStage stage;
  final double hingeAngle;
  final ScreenOrientation orientation;
  final DateTime timestamp;

  factory FoldState.fromMap(Map<dynamic, dynamic> map) {
    final rawAngle = map['hingeAngle'];
    final rawTimestamp = map['timestamp'];
    return FoldState(
      stage: FoldStage.fromRaw(map['stage'] as String?),
      hingeAngle: rawAngle is num ? rawAngle.toDouble() : 0,
      orientation: ScreenOrientation.fromRaw(map['orientation'] as String?),
      timestamp: rawTimestamp is num
          ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoldState &&
        other.stage == stage &&
        other.hingeAngle == hingeAngle &&
        other.orientation == orientation &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(stage, hingeAngle, orientation, timestamp);

  @override
  String toString() {
    return 'FoldState(stage: $stage, hingeAngle: $hingeAngle, '
        'orientation: $orientation, timestamp: $timestamp)';
  }
}
