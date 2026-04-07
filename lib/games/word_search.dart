import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class WordSearchGame extends StatefulWidget {
  final Function(int points) onScore;
  final VoidCallback onWin;
  final bool isActive;

  const WordSearchGame({
    super.key,
    required this.onScore,
    required this.onWin,
    required this.isActive,
  });

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  static const int gridSize = 9;
  static const List<String> wordBank = [
    'FLUTTER',
    'GAME',
    'CODE',
    'PLAY',
    'FUN',
    'DART',
    'APP',
    'DEV',
    'RUN',
    'SWIPE',
  ];

  late List<List<String>> _grid;
  late List<String> _targetWords;
  final Set<String> _foundWords = {};
  final Set<String> _foundCells = {};
  final List<_WordPlacement> _placements = [];

  int? _startRow, _startCol;
  List<_GridCell> _selectedCells = [];
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final rng = Random();
    _targetWords = (wordBank.toList()..shuffle(rng)).take(5).toList();
    _grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    _placements.clear();

    for (final word in _targetWords) {
      _placeWord(word, rng);
    }

    // Fill remaining with random letters
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_grid[r][c].isEmpty) {
          _grid[r][c] = letters[rng.nextInt(letters.length)];
        }
      }
    }
  }

  bool _placeWord(String word, Random rng) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [0, -1],
      [-1, 0],
      [-1, -1],
      [1, -1],
      [-1, 1],
    ];

    for (int attempt = 0; attempt < 100; attempt++) {
      final dir = directions[rng.nextInt(directions.length)];
      final startR = rng.nextInt(gridSize);
      final startC = rng.nextInt(gridSize);
      bool fits = true;
      final cells = <_GridCell>[];

      for (int i = 0; i < word.length; i++) {
        final r = startR + dir[0] * i;
        final c = startC + dir[1] * i;
        if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
          fits = false;
          break;
        }
        if (_grid[r][c].isNotEmpty && _grid[r][c] != word[i]) {
          fits = false;
          break;
        }
        cells.add(_GridCell(r, c));
      }

      if (fits) {
        for (int i = 0; i < word.length; i++) {
          _grid[cells[i].row][cells[i].col] = word[i];
        }
        _placements.add(_WordPlacement(word, cells));
        return true;
      }
    }
    return false;
  }

  void _onPanStart(DragStartDetails details, double cellSize) {
    if (!widget.isActive) return;
    final col = (details.localPosition.dx / cellSize).floor();
    final row = (details.localPosition.dy / cellSize).floor();
    if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
      setState(() {
        _isDragging = true;
        _startRow = row;
        _startCol = col;
        _selectedCells = [_GridCell(row, col)];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double cellSize) {
    if (!_isDragging || _startRow == null) return;
    final col = (details.localPosition.dx / cellSize).floor();
    final row = (details.localPosition.dy / cellSize).floor();
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return;

    // Build straight line from start to current
    final cells = _buildLine(_startRow!, _startCol!, row, col);
    setState(() => _selectedCells = cells);
  }

  List<_GridCell> _buildLine(int r1, int c1, int r2, int c2) {
    final dr = (r2 - r1).sign;
    final dc = (c2 - c1).sign;
    final cells = <_GridCell>[];
    int r = r1, c = c1;
    while (true) {
      cells.add(_GridCell(r, c));
      if (r == r2 && c == c2) break;
      r += dr;
      c += dc;
      if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) break;
    }
    return cells;
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isDragging) return;
    _isDragging = false;

    final selected = _selectedCells.map((c) => _grid[c.row][c.col]).join();
    final reversed = selected.split('').reversed.join();

    for (final placement in _placements) {
      if (!_foundWords.contains(placement.word) &&
          (placement.word == selected || placement.word == reversed)) {
        setState(() {
          _foundWords.add(placement.word);
          for (final c in placement.cells) {
            _foundCells.add('${c.row},${c.col}');
          }
          _selectedCells = [];
        });

        widget.onScore(placement.word.length * 20);

        if (_foundWords.length == _targetWords.length) {
          widget.onWin();
        }
        return;
      }
    }

    setState(() => _selectedCells = []);
  }

  bool _isSelected(int r, int c) =>
      _selectedCells.any((cell) => cell.row == r && cell.col == c);

  bool _isFound(int r, int c) => _foundCells.contains('$r,$c');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Word list
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _targetWords.map((word) {
              final found = _foundWords.contains(word);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: found
                      ? AppColors.wordFound.withOpacity(0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: found ? AppColors.wordFound : AppColors.textMuted,
                  ),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    color:
                        found ? AppColors.wordFound : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: found ? TextDecoration.lineThrough : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Grid
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final cellSize = min(
              constraints.maxWidth / gridSize,
              constraints.maxHeight / gridSize,
            );
            final gridDim = cellSize * gridSize;

            return Center(
              child: SizedBox(
                width: gridDim,
                height: gridDim,
                child: GestureDetector(
                  onPanStart: (d) => _onPanStart(d, cellSize),
                  onPanUpdate: (d) => _onPanUpdate(d, cellSize),
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    children: [
                      // Grid cells
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (_, index) {
                          final r = index ~/ gridSize;
                          final c = index % gridSize;
                          final sel = _isSelected(r, c);
                          final found = _isFound(r, c);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: found
                                  ? AppColors.wordFound.withValues(alpha: 0.3)
                                  : sel
                                      ? AppColors.wordSelect.withValues(alpha: 0.4)
                                      : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: found
                                    ? AppColors.wordFound.withValues(alpha: 0.5)
                                    : sel
                                        ? AppColors.wordSelect
                                        : Colors.transparent,
                                width: sel || found ? 1 : 0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _grid[r][c],
                                style: TextStyle(
                                  color: found
                                      ? AppColors.wordFound
                                      : sel
                                          ? AppColors.wordSelect
                                          : AppColors.textPrimary,
                                  fontWeight: (sel || found)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: cellSize * 0.38,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GridCell {
  final int row, col;
  const _GridCell(this.row, this.col);
}

class _WordPlacement {
  final String word;
  final List<_GridCell> cells;
  const _WordPlacement(this.word, this.cells);
}
