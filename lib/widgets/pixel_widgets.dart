import 'package:flutter/material.dart';
import '../theme.dart';

class _Face extends StatelessWidget {
  const _Face({required this.down, required this.color, required this.child, this.padding});
  final bool down;
  final Color color;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: down ? const Offset(4, 4) : Offset.zero,
    child: Container(
      padding: padding,
      decoration: pixelBox(color: color, shadow: down ? 0 : 4),
      child: child,
    ),
  );
}

/// Tap button: Play, Restart, Home, OK...
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.onTap,
    this.label,
    this.icon,
    this.color = C.red,
    this.textColor = Colors.white,
    this.fontSize = 14,
  });
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final double fontSize;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _down = true),
    onTapUp: (_) => setState(() => _down = false),
    onTapCancel: () => setState(() => _down = false),
    onTap: widget.onTap,
    child: _Face(
      down: _down,
      color: widget.color,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.icon != null)
          Icon(widget.icon, color: widget.textColor, size: widget.fontSize * 1.8),
        if (widget.icon != null && widget.label != null) const SizedBox(width: 10),
        if (widget.label != null)
          Text(widget.label!, style: pixel(widget.fontSize, color: widget.textColor)),
      ]),
    ),
  );
}

/// Up / Down button: active while the finger is held down.
class HoldButton extends StatefulWidget {
  const HoldButton({super.key, required this.icon, required this.onChanged});
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: _Face(
      down: _down,
      color: C.blue,
      child: SizedBox.square(
        dimension: 84,
        child: Icon(widget.icon, color: Colors.white, size: 52),
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  const Avatar(this.initial, {super.key, this.size = 44, this.color = C.blue});
  final String initial;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: C.navy, width: 3),
      boxShadow: const [BoxShadow(color: C.navy, offset: Offset(3, 3))],
    ),
    child: Text(initial, style: pixel(size * 0.36, color: Colors.white)),
  );
}