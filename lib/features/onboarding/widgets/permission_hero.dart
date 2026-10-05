import 'package:filevault/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Vault + shield illustration from the Stitch permission screen.
class PermissionHeroArt extends StatelessWidget {
  const PermissionHeroArt({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.lightSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: _VaultPainter(dark: dark),
        ),
      ),
    );
  }
}

class _VaultPainter extends CustomPainter {
  _VaultPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final RRect vault = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.72, height: size.height * 0.58),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      vault,
      Paint()
        ..color = dark ? AppColors.darkSurfaceContainerHigh : AppColors.lightSurfaceContainerHighest,
    );

    void fileCard(Offset origin, Color fill) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx, origin.dy, 72, 82),
          const Radius.circular(10),
        ),
        Paint()..color = fill,
      );
    }

    fileCard(
      Offset(center.dx - 78, center.dy - 28),
      dark ? AppColors.darkSurfaceContainerLowest : Colors.white,
    );
    fileCard(
      Offset(center.dx + 6, center.dy - 34),
      dark ? AppColors.darkSurface : Colors.white,
    );

    final Path shield = Path()
      ..moveTo(center.dx, center.dy - 52)
      ..cubicTo(center.dx + 34, center.dy - 52, center.dx + 48, center.dy - 28, center.dx + 48, center.dy)
      ..cubicTo(center.dx + 48, center.dy + 42, center.dx + 16, center.dy + 70, center.dx, center.dy + 82)
      ..cubicTo(center.dx - 16, center.dy + 70, center.dx - 48, center.dy + 42, center.dx - 48, center.dy)
      ..cubicTo(center.dx - 48, center.dy - 28, center.dx - 34, center.dy - 52, center.dx, center.dy - 52)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0B6E99), Color(0xFF0045B9)],
        ).createShader(shield.getBounds()),
    );
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFFFDB244));
    canvas.drawCircle(center.translate(0, 2), 4, Paint()..color = const Color(0xFF6E4600));
  }

  @override
  bool shouldRepaint(covariant _VaultPainter oldDelegate) => oldDelegate.dark != dark;
}
