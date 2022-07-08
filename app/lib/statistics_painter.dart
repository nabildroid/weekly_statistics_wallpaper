import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class StatisticsPainter extends CustomPainter {
  final List<double> chartPoints;
  final int productivityValue;
  final List<double> habitPoints;
  final DateTime? start;

  final Color primary;
  final Color secondary;

  StatisticsPainter({
    required this.chartPoints,
    required this.productivityValue,
    required this.habitPoints,
    this.start,
    this.primary = Colors.white,
    this.secondary = Colors.black,
  });

  void moveTo(Canvas canvas, Size shapeSize, Size size) {
    canvas.translate(
      size.width - shapeSize.width / 2,
      size.height - shapeSize.height / 2,
    );
  }

  void drawProgressIndicator(Canvas canvas, Size size) {
    canvas.save();
    bool isUp = false;

    if (chartPoints.length > 1) {
      final points = chartPoints.reversed.toList();
      isUp = points[0] - points[1] > 0;
    }

    const shape = Size(30, 20);

    final path_reversed = Path()
      ..moveTo(0, 0)
      ..relativeLineTo(1, 0)
      ..relativeLineTo(-0.5, 1);

    final path = Path()
      ..moveTo(0.5, 0)
      ..relativeLineTo(0.5, 1)
      ..relativeLineTo(-1, 0);

    moveTo(
      canvas,
      shape,
      Size(
        size.width * .9 - 8,
        size.height * .06,
      ),
    );

    canvas.save();

    canvas.translate(-shape.width / 2, -shape.height * .7);

    canvas.scale(shape.width, shape.height);
    final traingle = isUp ? path : path_reversed;

    canvas.drawShadow(
      traingle.transform(Matrix4.diagonal3Values(2, 2, 1.0).storage),
      lighten(primary, .1).withOpacity(.3),
      10,
      true,
    );

    canvas.restore();
    canvas.scale(shape.width, shape.height);
    canvas.drawPath(
      traingle,
      Paint()
        ..color = primary
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  void drawWeeksIndicator(Canvas canvas, Size size) {
    canvas.save();

    canvas.translate(size.width * .1, size.height * .1);
    canvas.scale(size.width * .2);

    var currentWeek = Random().nextInt(25);

    if (start != null) {
      final diff = DateTime.now().difference(start!).inDays;

      currentWeek = min(diff ~/ 7, 25);
    }

    const cols = 5;
    const circleSize = .03;
    const gap = .8;
    const padding = gap / 2 - circleSize / 2;
    for (var i = 0; i < 25; i++) {
      final x = i ~/ cols * 1.0;
      final y = i - cols * x;
      final center = Offset(x * gap + padding, y * gap / 3 + padding);

      canvas.drawCircle(
        center,
        circleSize,
        Paint()
          ..color = primary.withOpacity(i == currentWeek ? 1 : .2)
          ..style = PaintingStyle.fill,
      );

      if (i == 9) {
        canvas.drawCircle(
          center,
          circleSize * 2,
          Paint()
            ..color = primary.withOpacity(i == currentWeek ? 1 : .5)
            ..style = PaintingStyle.stroke,
        );
      }
    }

    canvas.restore();
  }

  void drawCharts(Canvas canvas, Size size) {
    canvas.save();
    final minList = min(6, chartPoints.length);

    final List<double> values =
        chartPoints.reversed.toList().sublist(0, minList).reversed.toList();

    while (values.length < 11) {
      if (values.length % 2 == 0) {
        values.add(0);
      } else {
        values.insert(0, 0);
      }
    }

    canvas.translate(size.width * .1, size.height / 2);
    canvas.scale(size.width * .8, size.height * .3);

    const minHeight = .08;
    for (var i = 0; i < values.length; i++) {
      canvas.save();
      final value = values[i] + minHeight;

      final isLast = i == 7;

      canvas.translate(i * .1, -value / 2);
      canvas.drawLine(
        Offset.zero,
        Offset(0.0, value),
        Paint()
          ..color = primary.withOpacity(value == minHeight
              ? 0.3
              : isLast
                  ? 1
                  : .7)
          ..style = PaintingStyle.fill
          ..strokeWidth = .013,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void drawBottomIndicator(Canvas canvas, Size size) {
    canvas.save();
    const width = 4.0;
    canvas.translate(size.width * 0.1, size.height - width / 2);
    final List<double> values = habitPoints;

    const minHeight = 10;
    final maxHeight = size.width * 0.8 / values.length;

    for (var i = 0; i < values.length; i++) {
      final value = min(values[i] * maxHeight + minHeight, maxHeight);

      final shift = min((maxHeight - value) / 2, maxHeight).abs();

      final start = i * maxHeight;

      canvas.drawLine(
          Offset(start + shift, 0),
          Offset(start + value + shift, 0),
          Paint()
            ..color = primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = width);
    }

    canvas.restore();
  }

  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  void drawText(Canvas canvas, Size size) {
    canvas.save();
    final _pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontWeight: FontWeight.normal,
      fontSize: 12,
      textAlign: ui.TextAlign.right,
    ))
      ..pushStyle(ui.TextStyle(
        color: primary,
        letterSpacing: 2,
      ))
      ..addText(
          "YOU ARE PRODUCTIVE MORE\nTHAN $productivityValue% (S.M.O.L.2.G)");

    final pc = ui.ParagraphConstraints(width: size.width - 100);

    final paragraph = _pb.build()..layout(pc);
    canvas.drawParagraph(paragraph, Offset(50, size.height * .7));

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.largest,
      Paint()..color = secondary,
    );

    drawProgressIndicator(canvas, size);
    drawWeeksIndicator(canvas, size);
    drawCharts(canvas, size);
    drawText(canvas, size);
    drawBottomIndicator(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
