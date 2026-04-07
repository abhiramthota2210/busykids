import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BubbleBlastGame extends StatefulWidget {
  final Function(int points) onScore;
  final VoidCallback onWin;
  final bool isActive;

  const BubbleBlastGame({
    super.key,
    required this.onScore,
    required this.onWin,
    required this.isActive,
  });

  @override
  State<BubbleBlastGame> createState() => _BubbleBlastGameState();
}

class _BubbleBlastGameState extends State<BubbleBlastGame>
    with TickerProviderStateMixin {
  static const int cols = 8;
  static const int rows = 10;
  static const int colorCount = 5;

  late List<List<int>> _grid; // -1 = empty, 0-4 = color
  final Set<String> _popping = {};
  int _totalPopped = 0;
  final int _totalBubbles = cols * rows;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _initGrid();
  }

  void _initGrid() {
    final rng = Random();
    _grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => rng.nextInt(colorCount)),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  List<_Cell> _getCluster(int row, int col) {
    final color = _grid[row][col];
    if (color < 0) return [];
    final visited = <String>{};
    final cluster = <_Cell>[];
    final queue = [_Cell(row, col)];
    while (queue.isNotEmpty) {
      final c = queue.removeAt(0);
      final key = '${c.r},${c.c}';
      if (visited.contains(key)) continue;
      if (c.r < 0 || c.r >= rows || c.c < 0 || c.c >= cols) continue;
      if (_grid[c.r][c.c] != color) continue;
      visited.add(key);
      cluster.add(c);
      queue.addAll([
        _Cell(c.r - 1, c.c), _Cell(c.r + 1, c.c),
        _Cell(c.r, c.c - 1), _Cell(c.r, c.c + 1),
      ]);
    }
    return cluster;
  }

  void _onTap(int row, int col) {
    if (!widget.isActive) return;
    if (_grid[row][col] < 0) return;

    final cluster = _getCluster(row, col);
    if (cluster.length < 2) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      return;
    }

    setState(() {
      for (final c in cluster) {
        _popping.add('${c.r},${c.c}');
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        for (final c in cluster) {
          _grid[c.r][c.c] = -1;
          _popping.remove('${c.r},${c.c}');
        }
        _totalPopped += cluster.length;
        _applyGravity();
      });

      final pts = cluster.length * cluster.length * 10;
      widget.onScore(pts);

      if (_totalPopped >= (_totalBubbles * 0.7).floor()) {
        widget.onWin();
      }
    });
  }

  void _applyGravity() {
    for (int c = 0; c < cols; c++) {
      final column = <int>[];
      for (int r = rows - 1; r >= 0; r--) {
        if (_grid[r][c] >= 0) column.add(_grid[r][c]);
      }
      for (int r = rows - 1; r >= 0; r--) {
        _grid[r][c] = (rows - 1 - r) < column.length
            ? column[rows - 1 - r]
            : -1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cellSize = min(
        constraints.maxWidth / cols,
        constraints.maxHeight / rows,
      );
      return Center(
        child: SizedBox(
          width: cellSize * cols,
          height: cellSize * rows,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
            ),
            itemCount: rows * cols,
            itemBuilder: (context, index) {
              final row = index ~/ cols;
              final col = index % cols;
              final colorIdx = _grid[row][col];
              final key = '$row,$col';
              final isPopping = _popping.contains(key);

              return GestureDetector(
                onTap: () => _onTap(row, col),
                child: AnimatedScale(
                  scale: isPopping ? 0.0 : (colorIdx < 0 ? 0.0 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInBack,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: colorIdx >= 0
                        ? _BubbleWidget(color: AppColors.bubbleColors[colorIdx])
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _BubbleWidget extends StatelessWidget {
  final Color color;
  const _BubbleWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _Cell {
  final int r, c;
  const _Cell(this.r, this.c);
}