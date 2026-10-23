import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'fold_state.dart';
import 'fold_state_service.dart';

void main() {
  runApp(const DuoApp());
}

class DuoApp extends StatelessWidget {
  const DuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FoldHomePage(),
    );
  }
}

class FoldHomePage extends StatefulWidget {
  const FoldHomePage({super.key});

  @override
  State<FoldHomePage> createState() => _FoldHomePageState();
}

class _FoldHomePageState extends State<FoldHomePage> {
  final FoldStateService _service = FoldStateService();

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duo — Fold Monitor'),
        centerTitle: true,
      ),
      body: StreamBuilder<FoldState>(
        stream: _service.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _FoldDashboard(state: snapshot.data!);
        },
      ),
    );
  }
}

class _FoldDashboard extends StatelessWidget {
  const _FoldDashboard({required this.state});

  final FoldState state;

  @override
  Widget build(BuildContext context) {
    final details = _DetailsPanel(state: state);
    final hinge = _HingeVisualizer(state: state);
    final sideBySide = state.stage == FoldStage.fullyOpen;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: sideBySide
              ? Row(
                  key: const ValueKey('row'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: hinge)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(child: details),
                    ),
                  ],
                )
              : LayoutBuilder(
                  key: const ValueKey('column'),
                  builder: (context, constraints) {
                    final hingeSize = (constraints.maxHeight * 0.5)
                        .clamp(0.0, constraints.maxWidth);
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: hingeSize,
                              child: Center(child: hinge),
                            ),
                            const SizedBox(height: 16),
                            details,
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _HingeVisualizer extends StatelessWidget {
  const _HingeVisualizer({required this.state});

  final FoldState state;

  static double _angleForStage(FoldStage stage) {
    switch (stage) {
      case FoldStage.closed:
        return 0;
      case FoldStage.halfOpen:
        return 90;
      case FoldStage.fullyOpen:
        return 180;
      case FoldStage.unknown:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(context, state.stage);
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _angleForStage(state.stage)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, angle, _) {
          return CustomPaint(
            painter: _HingePainter(angleDegrees: angle, color: color),
          );
        },
      ),
    );
  }
}

class _HingePainter extends CustomPainter {
  _HingePainter({required this.angleDegrees, required this.color});

  final double angleDegrees;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final hinge = Offset(size.width / 2, size.height * 0.75);
    final panelLength = size.height * 0.45;
    final panelWidth = size.width * 0.28;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    _drawPanel(canvas, hinge, -math.pi / 2, panelLength, panelWidth, fill,
        stroke);

    final rightAngle = -math.pi / 2 + (angleDegrees * math.pi / 180);
    _drawPanel(canvas, hinge, rightAngle, panelLength, panelWidth, fill,
        stroke);

    canvas.drawCircle(hinge, 7, Paint()..color = Colors.white);
    canvas.drawCircle(hinge, 7, stroke);
  }

  void _drawPanel(
    Canvas canvas,
    Offset hinge,
    double angle,
    double length,
    double width,
    Paint fill,
    Paint stroke,
  ) {
    canvas.save();
    canvas.translate(hinge.dx, hinge.dy);
    canvas.rotate(angle);
    final rect = Rect.fromLTWH(0, -width / 2, length, width);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HingePainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees ||
        oldDelegate.color != color;
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.state});

  final FoldState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android,
                    color: _stageColor(context, state.stage)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Fold State',
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _StatRow(
              label: 'Stage',
              value: state.stage.label,
              valueColor: _stageColor(context, state.stage),
            ),
            const Divider(height: 24),
            const _AuthorLinks(),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Could not read fold state',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Color _stageColor(BuildContext context, FoldStage stage) {
  switch (stage) {
    case FoldStage.closed:
      return Colors.redAccent;
    case FoldStage.halfOpen:
      return Colors.amber;
    case FoldStage.fullyOpen:
      return Colors.greenAccent;
    case FoldStage.unknown:
      return Theme.of(context).disabledColor;
  }
}

class _AuthorLink {
  const _AuthorLink({
    required this.icon,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final String tooltip;
  final String url;
}

class _AuthorLinks extends StatelessWidget {
  const _AuthorLinks();

  static const String _websiteLabel = 'radikadilanka.com';
  static const String _websiteUrl = 'https://radikadilanka.com';

  static const List<_AuthorLink> _links = [
    _AuthorLink(
      icon: Icons.language,
      tooltip: 'Website',
      url: _websiteUrl,
    ),
    _AuthorLink(
      icon: Icons.code,
      tooltip: 'GitHub',
      url: 'https://github.com/radika-insfra',
    ),
    _AuthorLink(
      icon: Icons.alternate_email,
      tooltip: 'X (Twitter)',
      url: 'https://x.com/radikadilanka',
    ),
    _AuthorLink(
      icon: Icons.business_center,
      tooltip: 'LinkedIn',
      url: 'https://www.linkedin.com/in/radikadilanka',
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error opening $url: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _open(context, _websiteUrl),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Built by '),
                  TextSpan(
                    text: _websiteLabel,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            for (final link in _links)
              IconButton(
                icon: Icon(link.icon),
                iconSize: 20,
                tooltip: link.tooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () => _open(context, link.url),
              ),
          ],
        ),
      ],
    );
  }
}
