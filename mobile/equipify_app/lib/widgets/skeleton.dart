import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Shimmering placeholder used while images/data load.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius});
  final double? width;
  final double? height;
  final double? radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius ?? EqRadius.card),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value, 0),
            end: Alignment(0 + 2 * _c.value, 0),
            colors: [
              base.withValues(alpha: 0.5),
              base.withValues(alpha: 0.9),
              base.withValues(alpha: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
