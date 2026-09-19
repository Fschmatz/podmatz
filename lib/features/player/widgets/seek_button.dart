import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

class SeekButton extends StatefulWidget {
  const SeekButton({
    super.key,
    required this.forward,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.intervalSeconds = 15,
  });

  final bool forward;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final int intervalSeconds;

  @override
  State<SeekButton> createState() => _SeekButtonState();
}

class _SeekButtonState extends State<SeekButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) {
      setState(() {
        _down = value;
      });
    }
  }

  Widget _buildIcon() {
    if (widget.intervalSeconds == 10) {
      return Icon(
        widget.forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
        color: widget.iconColor,
        size: 28,
      );
    } else if (widget.intervalSeconds == 30) {
      return Icon(
        widget.forward ? Icons.forward_30_rounded : Icons.replay_30_rounded,
        color: widget.iconColor,
        size: 28,
      );
    } else if (widget.intervalSeconds == 5) {
      return Icon(
        widget.forward ? Icons.forward_5_rounded : Icons.replay_5_rounded,
        color: widget.iconColor,
        size: 28,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.forward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
            color: widget.iconColor,
            size: 24,
          ),
          Text(
            '${widget.forward ? "+" : "-"}${widget.intervalSeconds}s',
            style: TextStyle(
              color: widget.iconColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double roundRadius = constraints.biggest.shortestSide / 2;
        return SingleMotionBuilder(
          motion: const MaterialSpringMotion.expressiveSpatialFast(),
          value: _down && !reduce ? 1.0 : 0.0,
          builder: (context, t, child) {
            final double radius =
                roundRadius + (12 - roundRadius) * t.clamp(0.0, 1.0);

            return ClipPath(
              clipper: ShapeBorderClipper(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              child: child,
            );
          },
          child: Material(
            color: widget.color,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                _setDown(true);
              },
              onTapUp: (_) {
                _setDown(false);
              },
              onTapCancel: () {
                _setDown(false);
              },
              child: SizedBox.expand(
                child: Center(
                  child: _buildIcon(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
