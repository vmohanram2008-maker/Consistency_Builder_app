import 'package:flutter/material.dart';

class GlowActionButton extends StatefulWidget {
  const GlowActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isOutlined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final bool isOutlined;
  final EdgeInsets padding;
  final bool fullWidth;

  @override
  State<GlowActionButton> createState() => _GlowActionButtonState();
}

class _GlowActionButtonState extends State<GlowActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF86B8FF);
    final glowColor = accent.withValues(alpha: 0.65);
    final borderColor = const Color(0xFFB9D9FF).withValues(alpha: 0.85);
    final fillColor = widget.isOutlined
        ? const Color(0xFF0D1E33).withValues(alpha: 0.7)
        : const Color(0xFF7AAEFF);
    final textColor = widget.isOutlined
        ? const Color(0xFFEAF4FF)
        : const Color(0xFF061626);

    final child = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 10),
        ],
        DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          child: widget.label,
        ),
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 1.05 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: widget.isOutlined
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF95C4FF), Color(0xFF7BAEFF), Color(0xFF5B8EEC)],
                ),
          border: widget.isOutlined
              ? Border.all(color: borderColor, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Padding(
              padding: widget.padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
