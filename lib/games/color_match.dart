import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class BlockBlastGame extends StatefulWidget {
  final Function(int points) onScore;
  final VoidCallback onWin;
  final bool isActive;

  const BlockBlastGame({
    super.key,
    required this.onScore,
    required this.onWin,
    required this.isActive,
  });

  @override
  State<BlockBlastGame> createState() => _BlockBlastGameState();
}

class _BlockBlastGameState extends State<BlockBlastGame>
    with SingleTickerProviderStateMixin {
  static const int gridCols = 7;
  static const int gridRows = 9;

  late List<List<Color?>> _grid;
  late List<_BlockPiece> _tray;
  int? _selectedIndex;
  int _rowsCleared = 0;
  static const int _rowsNeeded = 4;

  late AnimationController _clearController;
  Set<int> _clearingRows = {};

  static const List<List<List<int>>> _shapes = [
    [[1, 1], [1, 1]],
    [[1], [1], [1]],
    [[1, 1, 1]],
    [[1, 1, 0], [0, 1, 1]],
    [[0, 1, 1], [1, 1, 0]],
    [[1, 1, 1], [0, 1, 0]],
    [[1, 0], [1, 1]],
    [[0, 1], [1, 1]],
    [[1]],
    [[1, 1]],
  ];

  static const List<Color> _pieceColors = [
    AppColors.blockColor1, AppColors.blockColor2,
    AppColors.blockColor3, AppColors.blockColor4,
    AppColors.blockColor5,
  ];

  @override
  void initState() {
    super.initState();
    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initGame();
  }

  void _initGame() {
    _grid = List.generate(gridRows, (_) => List.filled(gridCols, null));
    _tray = _generateTray();
  }

  List<_BlockPiece> _generateTray() {
    final rng = Random();
    return List.generate(3, (_) {
      final shape = _shapes[rng.nextInt(_shapes.length)];
      final color = _pieceColors[rng.nextInt(_pieceColors.length)];
      return _BlockPiece(shape, color);
    });
  }

  @override
  void dispose() {
    _clearController.dispose();
    super.dispose();
  }

  bool _canPlace(_BlockPiece piece, int startRow, int startCol) {
    for (int r = 0; r < piece.shape.length; r++) {
      for (int c = 0; c < piece.shape[r].length; c++) {
        if (piece.shape[r][c] == 0) continue;
        final gr = startRow + r;
        final gc = startCol + c;
        if (gr < 0 || gr >= gridRows || gc < 0 || gc >= gridCols) return false;
        if (_grid[gr][gc] != null) return false;
      }
    }
    return true;
  }

  void _placePiece(_BlockPiece piece, int startRow, int startCol) {
    for (int r = 0; r < piece.shape.length; r++) {
      for (int c = 0; c < piece.shape[r].length; c++) {
        if (piece.shape[r][c] == 1) {
          _grid[startRow + r][startCol + c] = piece.color;
        }
      }
    }
    final cellCount = piece.shape
        .expand((row) => row)
        .where((v) => v == 1)
        .length;
    widget.onScore(cellCount * 10);
  }

  Future<void> _checkAndClearRows() async {
    final rowsToClear = <int>[];
    for (int r = 0; r < gridRows; r++) {
      if (_grid[r].every((c) => c != null)) {
        rowsToClear.add(r);
      }
    }

    if (rowsToClear.isEmpty) return;

    setState(() => _clearingRows = rowsToClear.toSet());
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      for (final r in rowsToClear) {
        _grid.removeAt(r);
        _grid.insert(0, List.filled(gridCols, null));
      }
      _clearingRows = {};
      _rowsCleared += rowsToClear.length;
    });

    widget.onScore(rowsToClear.length * 100);

    if (_rowsCleared >= _rowsNeeded) {
      widget.onWin();
    }
  }

  void _onCellTap(int row, int col) {
    if (!widget.isActive || _selectedIndex == null) return;
    final piece = _tray[_selectedIndex!];

    if (!_canPlace(piece, row, col)) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() {
      _placePiece(piece, row, col);
      _tray[_selectedIndex!] = _BlockPiece.empty();
      _selectedIndex = null;
    });

    _checkAndClearRows();

    // Refill tray if all used
    if (_tray.every((p) => p.isEmpty)) {
      setState(() => _tray = _generateTray());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Clear $_rowsNeeded rows  ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              ...List.generate(_rowsNeeded, (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _rowsCleared
                        ? AppColors.success
                        : AppColors.surfaceLight,
                    border: Border.all(
                      color: i < _rowsCleared
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),

        // Grid
        Expanded(
          flex: 3,
          child: LayoutBuilder(builder: (context, constraints) {
            final cellSize = min(
              constraints.maxWidth / gridCols,
              constraints.maxHeight / gridRows,
            );

            return Center(
              child: SizedBox(
                width: cellSize * gridCols,
                height: cellSize * gridRows,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCols,
                  ),
                  itemCount: gridRows * gridCols,
                  itemBuilder: (_, index) {
                    final r = index ~/ gridCols;
                    final c = index % gridCols;
                    final color = _grid[r][c];
                    final isClearing = _clearingRows.contains(r);

                    return GestureDetector(
                      onTap: () => _onCellTap(r, c),
                      child: AnimatedOpacity(
                        opacity: isClearing ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: color ?? AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: color != null
                                ? [BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 3,
                                  )]
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),

        // Tray
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_tray.length, (i) {
              final piece = _tray[i];
              final isSelected = _selectedIndex == i;

              return GestureDetector(
                onTap: piece.isEmpty
                    ? null
                    : () => setState(() =>
                        _selectedIndex = isSelected ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? piece.color.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? piece.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: piece.isEmpty
                      ? const SizedBox(width: 50, height: 50)
                      : _PieceWidget(piece: piece, cellSize: 14),
                ),
              );
            }),
          ),
        ),

        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Tap a cell on the grid to place',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlockPiece {
  final List<List<int>> shape;
  final Color color;
  bool get isEmpty => shape.isEmpty;

  const _BlockPiece(this.shape, this.color);

  factory _BlockPiece.empty() => _BlockPiece(const [], Colors.transparent);
}

class _PieceWidget extends StatelessWidget {
  final _BlockPiece piece;
  final double cellSize;

  const _PieceWidget({required this.piece, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: piece.shape.map((row) => Row(
        mainAxisSize: MainAxisSize.min,
        children: row.map((cell) => Container(
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: cell == 1 ? piece.color : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: cell == 1
                ? [BoxShadow(color: piece.color.withValues(alpha: 0.5), blurRadius: 3)]
                : null,
          ),
        )).toList(),
      )).toList(),
    );
  }
}