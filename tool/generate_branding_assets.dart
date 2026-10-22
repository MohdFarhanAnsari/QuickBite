import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate QuickBite Brand Assets (Icon, Adaptive Icon, Splash)', () async {
    final assetsDir = Directory('assets/logo');
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
    }

    // 1. Generate App Logo (Standard 1024x1024 icon on #FFF6F2 warm background)
    await _generateAppLogo(
      File('assets/logo/app_logo.png'),
      withBackground: true,
      size: 1024,
    );

    // 2. Generate Adaptive Icon Foreground (1024x1024 transparent, inside 66% safe zone)
    await _generateAppLogo(
      File('assets/logo/app_logo_foreground.png'),
      withBackground: false,
      size: 1024,
    );

    // 3. Generate Adaptive Icon Background (1024x1024 solid #FFF6F2)
    await _generateAdaptiveBackground(
      File('assets/logo/app_logo_background.png'),
      size: 1024,
    );

    // 4. Generate Android 12+ Splash Icon (1024x1024 transparent, scaled for 160dp window)
    await _generateSplashIconAndroid12(
      File('assets/logo/splash_icon_android12.png'),
      size: 1024,
    );

    // 5. Generate Full Splash Screen Logo (1024x1024, Logo + Wordmark + Tagline)
    await _generateFullSplashLogo(
      File('assets/logo/splash_logo.png'),
      size: 1024,
    );

    expect(File('assets/logo/app_logo.png').existsSync(), isTrue);
    expect(File('assets/logo/app_logo_foreground.png').existsSync(), isTrue);
    expect(File('assets/logo/app_logo_background.png').existsSync(), isTrue);
    expect(File('assets/logo/splash_icon_android12.png').existsSync(), isTrue);
    expect(File('assets/logo/splash_logo.png').existsSync(), isTrue);
  });
}

/// Generates the stylized QuickBite "Q" logo mark
void _drawQuickBiteMark(
  ui.Canvas canvas, {
  required ui.Offset center,
  required double scale,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);

  // Center of the main circular loop is at (0, -25)
  final loopCenter = const ui.Offset(0, -25);
  const outerR = 210.0;
  const innerR = 135.0;

  // 1. Base Ring Path for "Q"
  final outerCircle = ui.Path()
    ..addOval(ui.Rect.fromCircle(center: loopCenter, radius: outerR));
  final innerCircle = ui.Path()
    ..addOval(ui.Rect.fromCircle(center: loopCenter, radius: innerR));
  var ringPath = ui.Path.combine(
    ui.PathOperation.difference,
    outerCircle,
    innerCircle,
  );

  // 2. Playful, appetizing "Bite" cutout at top-right (around -32 degrees)
  const biteAngle = -35.0 * math.pi / 180.0;
  final biteCenter = ui.Offset(
    loopCenter.dx + outerR * math.cos(biteAngle),
    loopCenter.dy + outerR * math.sin(biteAngle),
  );
  final biteCutout = ui.Path()
    ..addOval(ui.Rect.fromCircle(center: biteCenter, radius: 56.0));

  ringPath = ui.Path.combine(ui.PathOperation.difference, ringPath, biteCutout);

  // Gradient for the primary "Q" ring: Warm Coral (#FF6B35) -> Deep Sunset Coral (#E85924)
  final ringShader = ui.Gradient.linear(
    ui.Offset(loopCenter.dx - outerR, loopCenter.dy - outerR),
    ui.Offset(loopCenter.dx + outerR, loopCenter.dy + outerR),
    [
      const ui.Color(0xFFFF7E47), // Vibrant coral
      const ui.Color(0xFFFF6B35), // Signature primary
      const ui.Color(0xFFE85924), // Rich deep coral
    ],
    [0.0, 0.55, 1.0],
  );

  final ringPaint = ui.Paint()
    ..shader = ringShader
    ..isAntiAlias = true
    ..style = ui.PaintingStyle.fill;

  canvas.drawPath(ringPath, ringPaint);

  // 3. Tail of the "Q" - Dynamic delivery speed streak / fork-tine at bottom-right
  // Originates at ~48 degrees and extends outward at 45 degrees
  final tailPath = ui.Path();
  tailPath.moveTo(95, 80);
  tailPath.cubicTo(145, 115, 195, 165, 235, 215);
  tailPath.arcToPoint(
    const ui.Offset(205, 245),
    radius: const ui.Radius.circular(22),
    clockwise: true,
  );
  tailPath.cubicTo(165, 210, 115, 160, 65, 125);
  tailPath.close();

  final tailShader = ui.Gradient.linear(
    const ui.Offset(65, 80),
    const ui.Offset(235, 245),
    [
      const ui.Color(0xFFFF6B35),
      const ui.Color(0xFFE85924),
      const ui.Color(0xFFCC4412),
    ],
    [0.0, 0.5, 1.0],
  );

  final tailPaint = ui.Paint()
    ..shader = tailShader
    ..isAntiAlias = true
    ..style = ui.PaintingStyle.fill;

  canvas.drawPath(tailPath, tailPaint);

  // Secondary aerodynamic speed streak (accentuating rapid delivery)
  final speedStrokePath = ui.Path();
  speedStrokePath.moveTo(135, 210);
  speedStrokePath.lineTo(195, 270);
  final speedPaint = ui.Paint()
    ..color =
        const ui.Color(0xFFFFB800) // Golden amber accent
    ..strokeWidth = 14
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;
  canvas.drawPath(speedStrokePath, speedPaint);

  // 4. Cloche Dome Lid Handle at the top of the "Q" loop
  final knobPaint = ui.Paint()
    ..color =
        const ui.Color(0xFF111827) // Deep Charcoal
    ..isAntiAlias = true
    ..style = ui.PaintingStyle.fill;

  // Knob stem & round handle
  final knobRect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(
      center: ui.Offset(loopCenter.dx, loopCenter.dy - outerR - 4),
      width: 44,
      height: 18,
    ),
    const ui.Radius.circular(9),
  );
  canvas.drawRRect(knobRect, knobPaint);

  // 5. Inside Counter Motif: Cloche Food Dome & Steam Aroma (Food delivery essence)
  // Base plate line
  final platePaint = ui.Paint()
    ..color = const ui.Color(0xFF111827)
    ..strokeWidth = 9
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;
  canvas.drawLine(
    ui.Offset(loopCenter.dx - 68, loopCenter.dy + 35),
    ui.Offset(loopCenter.dx + 68, loopCenter.dy + 35),
    platePaint,
  );

  // Cloche dome
  final domePath = ui.Path()
    ..moveTo(loopCenter.dx - 62, loopCenter.dy + 35)
    ..cubicTo(
      loopCenter.dx - 60,
      loopCenter.dy - 35,
      loopCenter.dx + 60,
      loopCenter.dy - 35,
      loopCenter.dx + 62,
      loopCenter.dy + 35,
    )
    ..close();

  final domePaint = ui.Paint()
    ..color = const ui.Color(0xFF111827)
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = true;
  canvas.drawPath(domePath, domePaint);

  // Dome handle knob
  canvas.drawCircle(
    ui.Offset(loopCenter.dx, loopCenter.dy - 38),
    7,
    ui.Paint()
      ..color = const ui.Color(0xFFFF6B35)
      ..isAntiAlias = true,
  );

  // Upward Steam / Aroma curls
  final steamPaint = ui.Paint()
    ..color = const ui.Color(0xFFFF8A5B)
    ..strokeWidth = 6.5
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke
    ..isAntiAlias = true;

  // Left steam
  final leftSteam = ui.Path()
    ..moveTo(loopCenter.dx - 22, loopCenter.dy - 50)
    ..cubicTo(
      loopCenter.dx - 32,
      loopCenter.dy - 68,
      loopCenter.dx - 12,
      loopCenter.dy - 82,
      loopCenter.dx - 20,
      loopCenter.dy - 98,
    );
  canvas.drawPath(leftSteam, steamPaint);

  // Center/Right steam (taller)
  final rightSteam = ui.Path()
    ..moveTo(loopCenter.dx + 18, loopCenter.dy - 50)
    ..cubicTo(
      loopCenter.dx + 30,
      loopCenter.dy - 72,
      loopCenter.dx + 8,
      loopCenter.dy - 90,
      loopCenter.dx + 22,
      loopCenter.dy - 110,
    );
  canvas.drawPath(rightSteam, steamPaint);

  canvas.restore();
}

/// Generates standard App Logo (1024x1024)
Future<void> _generateAppLogo(
  File targetFile, {
  required bool withBackground,
  required double size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  if (withBackground) {
    // Warm porcelain off-white background with subtle radial glow
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(size * 0.5, size * 0.45),
        size * 0.75,
        [
          const ui.Color(0xFFFFFFFF),
          const ui.Color(0xFFFFF6F2),
          const ui.Color(0xFFFFECE3),
        ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size), bgPaint);

    // Subtle premium border ring
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0x15FF6B35)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size), borderPaint);
  }

  // Draw mark scaled to fit safely within the central zone
  // Scale 1.15 places outer diameter at ~520px (well within 680px safe circle)
  _drawQuickBiteMark(
    canvas,
    center: ui.Offset(size * 0.5, size * 0.5),
    scale: 1.15,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  targetFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}

/// Generates solid adaptive icon background
Future<void> _generateAdaptiveBackground(
  File targetFile, {
  required double size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final bgPaint = ui.Paint()
    ..shader = ui.Gradient.radial(
      ui.Offset(size * 0.5, size * 0.5),
      size * 0.7,
      [
        const ui.Color(0xFFFFFFFF),
        const ui.Color(0xFFFFF6F2),
        const ui.Color(0xFFFFEDE6),
      ],
      [0.0, 0.7, 1.0],
    );
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size), bgPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  targetFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}

/// Generates Android 12+ Splash Icon (transparent, perfectly sized for 160dp central circle)
Future<void> _generateSplashIconAndroid12(
  File targetFile, {
  required double size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Scaled down to ~0.95 so it fits cleanly inside Android 12's 160dp circular mask with 0 clipping
  _drawQuickBiteMark(
    canvas,
    center: ui.Offset(size * 0.5, size * 0.5),
    scale: 0.98,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  targetFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}

/// Generates Full Splash Screen Logo with QuickBite Wordmark and Tagline
Future<void> _generateFullSplashLogo(
  File targetFile, {
  required double size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Draw QuickBite mark in upper half
  _drawQuickBiteMark(
    canvas,
    center: ui.Offset(size * 0.5, size * 0.38),
    scale: 0.88,
  );

  // Draw Wordmark: "QuickBite"
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  textPainter.text = const TextSpan(
    children: [
      TextSpan(
        text: 'Quick',
        style: TextStyle(
          color: Color(0xFF111827), // Deep charcoal
          fontSize: 78,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
      ),
      TextSpan(
        text: 'Bite',
        style: TextStyle(
          color: Color(0xFFFF6B35), // Signature Coral
          fontSize: 78,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
      ),
    ],
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    ui.Offset((size - textPainter.width) * 0.5, size * 0.64),
  );

  // Draw Tagline: "Good food. Quick delivery."
  final tagPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  tagPainter.text = const TextSpan(
    text: 'Good food. Quick delivery.',
    style: TextStyle(
      color: Color(0xFF6B7280), // Muted dark slate
      fontSize: 27,
      fontWeight: FontWeight.w500,
      letterSpacing: 2.2,
    ),
  );
  tagPainter.layout();
  tagPainter.paint(
    canvas,
    ui.Offset((size - tagPainter.width) * 0.5, size * 0.74),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  targetFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}
