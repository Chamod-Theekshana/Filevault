import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Number of digits in the Secure Folder PIN.
const int kPinLength = 6;

/// Six-dot PIN indicator with a shake animation on failure.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
    this.onDark = false,
  });

  final int length;
  final int filled;
  final bool error;

  /// Drawn on the deep vault ink (lock screens).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color fill = onDark ? Colors.white : context.colors.primaryContainer;
    final Color idle = onDark ? Colors.white.withValues(alpha: 0.45) : context.colors.outlineVariant;
    final Color bad = onDark ? const Color(0xFFFFB4AB) : context.colors.error;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: i < filled ? 16 : 14,
            height: i < filled ? 16 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? (error ? bad : fill) : Colors.transparent,
              border: Border.all(
                color: error
                    ? bad
                    : i < filled
                        ? fill
                        : idle,
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

/// Numeric keypad with optional biometric key.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
    this.onDark = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  /// Drawn on the deep vault ink (lock screens).
  final bool onDark;

  /// Natural height of the keypad (4 rows of 72dp keys).
  static const double naturalHeight = 288;

  @override
  Widget build(BuildContext context) {
    final Widget pad = _keys();
    // Short screens (landscape phones, split screen): shrink the keypad so the
    // PIN dots and message above it always stay visible.
    final double screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight >= 640) return pad;
    final double height = (screenHeight * 0.46).clamp(150.0, naturalHeight);
    return SizedBox(height: height, child: FittedBox(fit: BoxFit.scaleDown, child: pad));
  }

  Widget _keys() {
    final List<String> keys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int col = 0; col < 3; col++)
                _Key(
                  label: keys[row * 3 + col],
                  enabled: enabled,
                  onDark: onDark,
                  onTap: () => onDigit(keys[row * 3 + col]),
                ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (onBiometric != null)
              _Key(icon: Icons.fingerprint, enabled: enabled, onDark: onDark, onTap: onBiometric!)
            else
              const SizedBox(width: 84, height: 72),
            _Key(label: '0', enabled: enabled, onDark: onDark, onTap: () => onDigit('0')),
            _Key(icon: Icons.backspace_outlined, enabled: enabled, onDark: onDark, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.onTap,
    required this.enabled,
    this.onDark = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color ink = onDark
        ? Colors.white.withValues(alpha: enabled ? 1 : 0.4)
        : (enabled ? context.colors.onSurface : context.colors.outline);
    final Color iconInk = onDark
        ? Colors.white.withValues(alpha: enabled ? 0.9 : 0.4)
        : (enabled ? context.colors.onSurfaceVariant : context.colors.outline);
    return SizedBox(
      width: 84,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: label == null
              ? Colors.transparent
              : onDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : (context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            child: Center(
              child: label != null
                  ? Text(label!, style: context.texts.headlineMedium?.copyWith(color: ink))
                  : Icon(icon, size: 26, color: iconInk),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shakes its child horizontally whenever [trigger] changes.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(ShakeOnChange old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double offset = t == 0 ? 0 : (1 - t) * 12 * _wave(t);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }

  static double _wave(double t) {
    // Four quick oscillations over the animation.
    return (t * 8).floor().isEven ? 1 : -1;
  }
}
