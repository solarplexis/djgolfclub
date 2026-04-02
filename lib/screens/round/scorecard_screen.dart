import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/round.dart';
import '../../models/player.dart';
import '../../providers/round_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  int _currentHole = 1;

  @override
  Widget build(BuildContext context) {
    final round = context.watch<RoundProvider>().activeRound!;
    final hole = round.course.holes[_currentHole - 1];
    final holeScore = round.scores[_currentHole]!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(round.course.name.toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmAbandon(context),
        ),
        actions: [
          if (round.isComplete)
            TextButton(
              onPressed: () => _finishRound(context),
              child: const Text('FINISH',
                  style: TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Hole header
          Container(
            color: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentHole > 1
                      ? () => setState(() => _currentHole--)
                      : null,
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.white, size: 32),
                ),
                Column(
                  children: [
                    Text(
                      'HOLE $_currentHole',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.white,
                        fontSize: 40,
                      ),
                    ),
                    Text(
                      'PAR ${hole.par}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _currentHole < round.course.holeCount
                      ? () => setState(() => _currentHole++)
                      : null,
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.white, size: 32),
                ),
              ],
            ),
          ),

          // Player score inputs
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: round.players.map((player) {
                final strokes = holeScore.strokes[player.id];
                return _PlayerScoreRow(
                  player: player,
                  strokes: strokes,
                  par: hole.par,
                  onChanged: (s) => context
                      .read<RoundProvider>()
                      .updateScore(_currentHole, player.id!, s),
                );
              }).toList(),
            ),
          ),

          // Running totals
          _Totals(round: round),

          // Hole progress dots
          _HoleDots(
            holeCount: round.course.holeCount,
            current: _currentHole,
            scores: round.scores,
            players: round.players,
            onTap: (h) => setState(() => _currentHole = h),
          ),
        ],
      ),
    );
  }

  void _confirmAbandon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Round?'),
        content: const Text('Your scores will not be saved to history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Playing')),
          TextButton(
            onPressed: () {
              context.read<RoundProvider>().abandonRound();
              Navigator.pop(ctx);
            },
            child: const Text('Abandon', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishRound(BuildContext context) async {
    final courses = context.read<CourseProvider>().courses;
    final players = context.read<PlayerProvider>().players;
    await context.read<RoundProvider>().finishRound(courses, players);
  }
}

class _PlayerScoreRow extends StatelessWidget {
  final Player player;
  final int? strokes;
  final int par;
  final ValueChanged<int> onChanged;

  const _PlayerScoreRow({
    required this.player,
    required this.strokes,
    required this.par,
    required this.onChanged,
  });

  Color _strokeColor(int? s) {
    if (s == null) return AppColors.textMuted;
    final diff = s - par;
    if (diff <= -2) return AppColors.eagle;
    if (diff == -1) return AppColors.birdie;
    if (diff == 0) return AppColors.par;
    if (diff == 1) return AppColors.bogey;
    return AppColors.doubleBogeyPlus;
  }

  String _scoreLabel(int? s) {
    if (s == null) return '-';
    final diff = s - par;
    if (diff <= -2) return 'Eagle';
    if (diff == -1) return 'Birdie';
    if (diff == 0) return 'Par';
    if (diff == 1) return 'Bogey';
    if (diff == 2) return 'Dbl Bogey';
    return '+$diff';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Player name
            Expanded(
              child: Text(player.name, style: theme.textTheme.titleLarge),
            ),

            // Score label
            SizedBox(
              width: 90,
              child: Text(
                _scoreLabel(strokes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _strokeColor(strokes),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Stepper
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: strokes != null && strokes! > 1
                      ? () => onChanged(strokes! - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.green,
                  iconSize: 28,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    strokes?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _strokeColor(strokes),
                      fontSize: 28,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onChanged((strokes ?? par - 1) + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.green,
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final Round round;
  const _Totals({required this.round});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.green,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: round.players.map((p) {
          final total = round.totalFor(p);
          final par = round.course.totalPar;
          final diff = total != null ? total - par : null;
          return Column(
            children: [
              Text(p.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.white.withAlpha(200))),
              Text(
                total?.toString() ?? '-',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontSize: 26,
                ),
              ),
              if (diff != null)
                Text(
                  diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: diff == 0
                        ? AppColors.gold
                        : diff < 0
                            ? AppColors.eagle
                            : AppColors.bogey.withAlpha(220),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _HoleDots extends StatelessWidget {
  final int holeCount;
  final int current;
  final Map<int, HoleScore> scores;
  final List<Player> players;
  final ValueChanged<int> onTap;

  const _HoleDots({
    required this.holeCount,
    required this.current,
    required this.scores,
    required this.players,
    required this.onTap,
  });

  bool _holeComplete(int hole) {
    final hs = scores[hole];
    if (hs == null) return false;
    return hs.strokes.values.every((s) => s != null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(holeCount, (i) {
          final hole = i + 1;
          final isActive = hole == current;
          final isDone = _holeComplete(hole);
          return GestureDetector(
            onTap: () => onTap(hole),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 20 : 14,
              height: isActive ? 20 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.gold
                    : isDone
                        ? AppColors.green
                        : AppColors.divider,
                border: isActive
                    ? Border.all(color: AppColors.green, width: 2)
                    : null,
              ),
              child: isActive
                  ? Center(
                      child: Text(
                        '$hole',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
