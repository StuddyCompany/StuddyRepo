import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NoiseBackground extends StatelessWidget {
  const NoiseBackground({super.key, this.cellSize = 40, this.seed = 7});

  final double cellSize;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _NoisePainter(cellSize: cellSize, seed: seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.cellSize, required this.seed});

  final double cellSize;
  final int seed;

  static const double _pixel = 3;
  static const double _threshold = 0.5;

  Path? _cachedPath;
  Size? _cachedSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.navy);

    if (_cachedPath == null || _cachedSize != size) {
      final path = Path();
      for (double y = 0; y < size.height; y += _pixel) {
        for (double x = 0; x < size.width; x += _pixel) {
          if (_fbm(x, y) > _threshold) {
            path.addRect(Rect.fromLTWH(x, y, _pixel + 0.5, _pixel + 0.5));
          }
        }
      }
      _cachedPath = path;
      _cachedSize = size;
    }
    canvas.drawPath(_cachedPath!, Paint()..color = AppColors.blue);
  }

  double _fbm(double x, double y) {
    return 0.6 * _valueNoise(x / cellSize, y / cellSize) +
        0.3 * _valueNoise(x / (cellSize / 2), y / (cellSize / 2)) +
        0.1 * _valueNoise(x / (cellSize / 4), y / (cellSize / 4));
  }

  double _valueNoise(double x, double y) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;
    final u = xf * xf * (3 - 2 * xf);
    final v = yf * yf * (3 - 2 * yf);

    final a = _rand(xi, yi);
    final b = _rand(xi + 1, yi);
    final c = _rand(xi, yi + 1);
    final d = _rand(xi + 1, yi + 1);

    final top = a + (b - a) * u;
    final bottom = c + (d - c) * u;
    return top + (bottom - top) * v;
  }

  double _rand(int x, int y) {
    final n = math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453;
    return n - n.floorToDouble();
  }

  @override
  bool shouldRepaint(_NoisePainter old) =>
      old.cellSize != cellSize || old.seed != seed;
}
