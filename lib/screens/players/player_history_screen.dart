import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../providers/round_provider.dart';
import '../../theme/app_theme.dart';

class PlayerHistoryScreen extends StatelessWidget {
  final Player player;
  const PlayerHistoryScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRounds = context.watch<RoundProvider>().history;

    // Only rounds this player participated in
    final rounds = allRounds
        .where((r) => r.players.any((p) => p.id == player.id))
        .toList();

    // Group rounds by course
    final Map<String, List<Round>> byCourse = {};
    for (final r in rounds) {
      byCourse.putIfAbsent(r.course.name, () => []).add(r);
    }

    // Sort courses alphabetically
    final courseNames = byCourse.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name.toUpperCase()),
      ),
      body: rounds.isEmpty
          ? _EmptyState(player: player)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: courseNames.length,
              itemBuilder: (ctx, i) {
                final courseName = courseNames[i];
                final courseRounds = byCourse[courseName]!;
                return _CourseStatsCard(
                  courseName: courseName,
                  rounds: courseRounds,
                  player: player,
                  theme: theme,
                );
              },
            ),
    );
  }
}

class _CourseStatsCard extends StatelessWidget {
  final String courseName;
  final List<Round> rounds;
  final Player player;
  final ThemeData theme;

  const _CourseStatsCard({
    required this.courseName,
    required this.rounds,
    required this.player,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final totals =
        rounds.map((r) => r.totalFor(player)).whereType<int>().toList();

    final par = rounds.first.course.totalPar;
    final roundsPlayed = rounds.length;
    final completedRounds = totals.length;

    final best = totals.isEmpty ? null : totals.reduce((a, b) => a < b ? a : b);
    final worst =
        totals.isEmpty ? null : totals.reduce((a, b) => a > b ? a : b);
    final avg = totals.isEmpty
        ? null
        : totals.fold(0, (sum, t) => sum + t) / totals.length;

    // Count wins
    final wins = rounds.where((r) {
      final myTotal = r.totalFor(player);
      if (myTotal == null) return false;
      final winnerTotal = r.players
          .map((p) => r.totalFor(p))
          .whereType<int>()
          .fold<int?>(null, (best, t) => best == null || t < best ? t : best);
      return myTotal == winnerTotal;
    }).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseName.toUpperCase(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$roundsPlayed round${roundsPlayed == 1 ? '' : 's'} played'
              '${completedRounds < roundsPlayed ? ' ($completedRounds complete)' : ''}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (totals.isEmpty)
              Text('No completed rounds',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: 'BEST',
                    value: best!,
                    par: par,
                    theme: theme,
                    highlight: true,
                  ),
                  _StatColumn(
                    label: 'AVG',
                    value: avg!.round(),
                    par: par,
                    theme: theme,
                  ),
                  _StatColumn(
                    label: 'WORST',
                    value: worst!,
                    par: par,
                    theme: theme,
                  ),
                  _WinsColumn(wins: wins, total: roundsPlayed, theme: theme),
                ],
              ),
            if (totals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _HoleBreakdownTable(
                rounds: rounds,
                player: player,
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoleBreakdownTable extends StatelessWidget {
  final List<Round> rounds;
  final Player player;
  final ThemeData theme;

  const _HoleBreakdownTable({
    required this.rounds,
    required this.player,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final holes = rounds.first.course.holes.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    // For each hole, collect all strokes across rounds
    final Map<int, List<int>> strokesByHole = {};
    for (final hole in holes) {
      strokesByHole[hole.number] = rounds
          .map((r) => r.scores[hole.number]?.strokes[player.id])
          .whereType<int>()
          .toList();
    }

    if (holes.length == 18) {
      final front = holes.sublist(0, 9);
      final back = holes.sublist(9, 18);
      return LayoutBuilder(builder: (context, constraints) {
        // Fixed label column + equal-width data columns that fill available width
        const labelWidth = 40.0;
        final cellWidth = (constraints.maxWidth - labelWidth) / 9;
        final colWidths = <int, TableColumnWidth>{
          0: const FixedColumnWidth(labelWidth),
          for (var i = 1; i <= 9; i++) i: FixedColumnWidth(cellWidth),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _halfLabel('FRONT 9', theme),
            const SizedBox(height: 6),
            _buildTable(front, strokesByHole, theme, colWidths),
            const SizedBox(height: 12),
            _halfLabel('BACK 9', theme),
            const SizedBox(height: 6),
            _buildTable(back, strokesByHole, theme, colWidths),
          ],
        );
      });
    }

    // Non-18-hole course — keep horizontal scroll
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _buildTable(holes, strokesByHole, theme, null),
    );
  }

  Widget _halfLabel(String text, ThemeData theme) => Text(
        text,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: AppColors.textMuted, letterSpacing: 1),
      );

  Widget _buildTable(
    List<dynamic> holeList,
    Map<int, List<int>> strokesByHole,
    ThemeData theme,
    Map<int, TableColumnWidth>? columnWidths,
  ) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      columnWidths: columnWidths,
      border: TableBorder.all(color: AppColors.divider, width: 1),
      children: [
        // Header row — hole numbers
        TableRow(
          decoration: const BoxDecoration(color: AppColors.green),
          children: [
            _headerCell('', theme),
            ...holeList.map((h) => _headerCell('${h.number}', theme)),
          ],
        ),
        // Par row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFEAF2EF)),
          children: [
            _labelCell('Par', theme),
            ...holeList.map((h) => _plainCell('${h.par}', theme, bold: true)),
          ],
        ),
        // Avg row
        TableRow(
          children: [
            _labelCell('Avg', theme),
            ...holeList.map((h) {
              final strokes = strokesByHole[h.number]!;
              if (strokes.isEmpty) return _plainCell('-', theme);
              final avg = strokes.fold(0, (s, v) => s + v) / strokes.length;
              return _scoreCell(avg.round(), h.par, theme);
            }),
          ],
        ),
        // Best row
        TableRow(
          children: [
            _labelCell('Best', theme),
            ...holeList.map((h) {
              final strokes = strokesByHole[h.number]!;
              if (strokes.isEmpty) return _plainCell('-', theme);
              final best = strokes.reduce((a, b) => a < b ? a : b);
              return _scoreCell(best, h.par, theme);
            }),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );

  Widget _labelCell(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _plainCell(String text, ThemeData theme, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );

  Widget _scoreCell(int strokes, int par, ThemeData theme) {
    final diff = strokes - par;
    Color bg = Colors.transparent;
    Color textColor = AppColors.textDark;
    bool circle = false;
    bool square = false;
    if (diff <= -2) {
      bg = AppColors.eagle.withAlpha(40);
      textColor = AppColors.eagle;
      circle = true;
    } else if (diff == -1) {
      bg = AppColors.birdie.withAlpha(30);
      textColor = AppColors.birdie;
      circle = true;
    } else if (diff == 1) {
      bg = AppColors.bogey.withAlpha(20);
      textColor = AppColors.bogey;
      square = true;
    } else if (diff >= 2) {
      bg = AppColors.doubleBogeyPlus.withAlpha(25);
      textColor = AppColors.doubleBogeyPlus;
      square = true;
    }
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: square ? BorderRadius.circular(3) : null,
          border: (circle || square)
              ? Border.all(color: textColor.withAlpha(100))
              : null,
        ),
        child: Text(
          '$strokes',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;
  final int par;
  final ThemeData theme;
  final bool highlight;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.par,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final diff = value - par;
    final diffStr = diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff');
    final diffColor = diff < 0
        ? AppColors.birdie
        : diff == 0
            ? AppColors.par
            : AppColors.bogey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textMuted, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            color: highlight ? const Color(0xFF4CAF50) : AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          diffStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: diffColor,
          ),
        ),
      ],
    );
  }
}

class _WinsColumn extends StatelessWidget {
  final int wins;
  final int total;
  final ThemeData theme;

  const _WinsColumn(
      {required this.wins, required this.total, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('WINS',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textMuted, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          '$wins',
          style: theme.textTheme.titleLarge?.copyWith(
            color: wins > 0 ? const Color(0xFF4CAF50) : AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'of $total',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Player player;
  const _EmptyState({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_golf, size: 72, color: AppColors.greenLight),
          const SizedBox(height: 16),
          Text('No rounds yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${player.name.split(' ').first} hasn\'t played any rounds.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
