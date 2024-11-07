import 'package:flutter/material.dart';

import '../base/utils.dart';

class PlayerWavePainter extends CustomPainter {
  final List<double> waveformData;
  final bool showTop;
  final bool showBottom;
  final double animValue;
  final double scaleFactor;
  final Color waveColor;
  final StrokeCap waveCap;
  final double waveThickness;
  final Shader? fixedWaveGradient;
  final Shader? liveWaveGradient;
  final double spacing;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double audioProgress;
  final Color liveWaveColor;
  final VoidCallback pushBack;
  final bool callPushback;
  final double emptySpace;
  final double scrollScale;
  final bool showSeekLine;
  final double seekLineThickness;
  final Color seekLineColor;
  final WaveformType waveformType;

  PlayerWavePainter({
    required this.waveformData,
    required this.showTop,
    required this.showBottom,
    required this.animValue,
    required this.scaleFactor,
    required this.waveColor,
    required this.waveCap,
    required this.waveThickness,
    required this.dragOffset,
    required this.totalBackDistance,
    required this.spacing,
    required this.audioProgress,
    required this.liveWaveColor,
    required this.pushBack,
    required this.callPushback,
    required this.scrollScale,
    required this.seekLineThickness,
    required this.seekLineColor,
    required this.showSeekLine,
    required this.waveformType,
    required this.cachedAudioProgress,
    this.liveWaveGradient,
    this.fixedWaveGradient,
  })  : fixedWavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap
          ..shader = fixedWaveGradient,
        liveWavePaint = Paint()
          ..color = liveWaveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap
          ..shader = liveWaveGradient,
        emptySpace = spacing,
        middleLinePaint = Paint()
          ..color = seekLineColor
          ..strokeWidth = seekLineThickness;

  Paint fixedWavePaint;
  Paint liveWavePaint;
  Paint middleLinePaint;
  double cachedAudioProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(size, canvas);
    if (showSeekLine && waveformType.isLong) _drawMiddleLine(size, canvas);
  }

  @override
  bool shouldRepaint(PlayerWavePainter oldDelegate) => true;

  void _drawMiddleLine(Size size, Canvas canvas) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      middleLinePaint,
    );
  }

  void _drawWave(Size size, Canvas canvas) {
    if (waveformData.isEmpty) return;

    return waveformType.isLong
        ? _drawWaveLong(size, canvas)
        : _drawWaveFitWidth(size, canvas);
  }

  void _drawWaveLong(Size size, Canvas canvas) {
    final length = waveformData.length;
    final halfWidth = size.width * 0.5;
    final halfHeight = size.height * 0.5;

    if (cachedAudioProgress != audioProgress) {
      pushBack();
    }
    for (int i = 0; i < length; i++) {
      final currentDragPointer = dragOffset.dx - totalBackDistance.dx;
      final waveWidth = i * spacing;
      final dx = waveWidth + currentDragPointer + emptySpace;
      // +
      // (waveformType.isFitWidth ? 0 : halfWidth);
      final waveHeight =
          (waveformData[i] * animValue) * scaleFactor * scrollScale;
      final bottomDy = halfHeight + (showBottom ? waveHeight : 0);
      final topDy = halfHeight + (showTop ? -waveHeight : 0);

      // Only draw waves which are in visible viewport.
      if (dx > 0 && dx < halfWidth * 2) {
        canvas.drawLine(
          Offset(dx, bottomDy),
          Offset(dx, topDy),
          i < audioProgress * length ? liveWavePaint : fixedWavePaint,
        );
      }
    }
  }

  void _drawWaveFitWidth(Size size, Canvas canvas) {
    final length = waveformData.length;
    final halfHeight = size.height * 0.5;
    final segmentCount = (size.width / 8).toInt(); // Fixed segments
    // final segmentDuration = 1 / segmentCount; // Duration per segment
    final segmentWidth = size.width / segmentCount; // Width of each segment

    if (cachedAudioProgress != audioProgress) {
      pushBack();
    }

    for (int i = 0; i < segmentCount; i++) {
      // Position each segment along the X-axis
      final dx = i * segmentWidth +
          dragOffset.dx -
          totalBackDistance.dx +
          (i == 0 ? segmentWidth / 6 : 0);

      final dataIndex = (i * length) ~/ segmentCount;
      if (dataIndex < length) {
        final waveHeight =
            (waveformData[dataIndex] * animValue) * scaleFactor * scrollScale;

        final bottomDy = halfHeight + (showBottom ? waveHeight : 0);
        final topDy = halfHeight + (showTop ? -waveHeight : 0);

        // Determine paint style based on audio progress
        Paint wavePaint =
            i < audioProgress * length ? liveWavePaint : fixedWavePaint;

        // Only draw waves within the visible viewport
        if (dx >= 0 && dx < size.width) {
          canvas.drawLine(
            Offset(dx, bottomDy),
            Offset(dx, topDy),
            wavePaint,
          );
        }
      }
    }
  }
}
