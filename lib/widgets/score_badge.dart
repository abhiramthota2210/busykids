import 'package:flutter/material.dart';
import '../utils/app_colors.dart';


class ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const ScoreBadge({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedScoreBump extends StatefulWidget {
  final int score;
  final Color color;

  const AnimatedScoreBump(
      {super.key, required this.score, required this.color});

  @override
  State<AnimatedScoreBump> createState() => _AnimatedScoreBumpState();
}

class _AnimatedScoreBumpState extends State<AnimatedScoreBump>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _prevScore = widget.score;
  }

  @override
  void didUpdateWidget(AnimatedScoreBump old) {
    super.didUpdateWidget(old);
    if (widget.score != _prevScore) {
      _prevScore = widget.score;
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ScoreBadge(score: widget.score, color: widget.color),
    );
  }
}
