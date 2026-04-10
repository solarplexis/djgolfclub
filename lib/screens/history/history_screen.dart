import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/round_provider.dart';
import '../../models/round.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rounds = context.watch<RoundProvider>().history;

    if (rounds.isEmpty)
      return Scaffold(
          appBar: AppBar(title: const Text('HISTORY')), body: _EmptyState());

    // Group by course id, sort rounds within each group latest-first,
    // then sort groups by their most recent round date.
    final Map<int, List<Round>> grouped = {};
    for (final r in rounds) {
      grouped.putIfAbsent(r.course.id!, () => []).add(r);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    final courseGroups = grouped.values.toList()
      ..sort((a, b) => b.first.date.compareTo(a.first.date));

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORY')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: courseGroups.length,
        itemBuilder: (ctx, i) => _CourseGroup(rounds: courseGroups[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top-level accordion: one card per course
// ---------------------------------------------------------------------------
class _CourseGroup extends StatelessWidget {
  final List<Round> rounds; // sorted latest-first
  const _CourseGroup({required this.rounds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = rounds.first;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          latest.course.name.toUpperCase(),
          style: theme.textTheme.titleLarge,
        ),
        subtitle: Text(
          '${rounds.length} round${rounds.length == 1 ? '' : 's'} · Last played ${_formatDate(latest.date)}',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        trailing: _ScoreSummary(round: latest),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...rounds.map((r) => _RoundTile(round: r)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual round row inside an expanded course group
// ---------------------------------------------------------------------------
class _RoundTile extends StatelessWidget {
  final Round round;
  const _RoundTile({required this.round});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(round.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Round?'),
          content: const Text('This round will be removed from history.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ).then((v) => v ?? false),
      onDismissed: (_) => context.read<RoundProvider>().deleteRound(round.id!),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          _formatDate(round.date),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: _ScoreSummary(round: round),
        children: [_ScorecardTable(round: round)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable player-score chips shown in both levels of the accordion
// ---------------------------------------------------------------------------
class _ScoreSummary extends StatelessWidget {
  final Round round;
  const _ScoreSummary({required this.round});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final par = round.course.totalPar;
    final winnerTotal = round.players
        .map((p) => round.totalFor(p))
        .whereType<int>()
        .fold<int?>(null, (best, t) => best == null || t < best ? t : best);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: round.players.map((p) {
        final total = round.totalFor(p);
        final diff = total != null ? total - par : null;
        final isWinner = total != null && total == winnerTotal;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWinner
                    ? p.name.split(' ').first.toUpperCase()
                    : p.name.split(' ').first,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isWinner ? const Color(0xFF4CAF50) : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isWinner ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
              Text(
                total?.toString() ?? '-',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (diff != null)
                Text(
                  diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: diff < 0
                        ? AppColors.birdie
                        : diff == 0
                            ? AppColors.par
                            : AppColors.bogey,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ---------------------------------------------------------------------------
// Scorecard table
class _ScorecardTable extends StatelessWidget {
  final Round round;
  const _ScorecardTable({required this.round});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holes = round.course.holes;
    final players = round.players;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: AppColors.divider, width: 1),
        children: [
          // Header row — hole numbers
          TableRow(
            decoration: const BoxDecoration(color: AppColors.green),
            children: [
              _headerCell('', theme),
              ...holes.map((h) => _headerCell('${h.number}', theme)),
              _headerCell('TOT', theme),
            ],
          ),
          // Par row
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEAF2EF)),
            children: [
              _labelCell('Par', theme),
              ...holes.map((h) => _valueCell('${h.par}', theme, bold: true)),
              _valueCell('${round.course.totalPar}', theme, bold: true),
            ],
          ),
          // Player rows
          ...players.map((p) => TableRow(
                children: [
                  _labelCell(p.name.split(' ').first, theme),
                  ...holes.map((h) {
                    final s = round.scores[h.number]?.strokes[p.id];
                    return _scoreCell(s, h.par, theme);
                  }),
                  _totalCell(round.totalFor(p), round.course.totalPar, theme),
                ],
              )),
        ],
      ),
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

  Widget _valueCell(String text, ThemeData theme, {bool bold = false}) =>
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

  Widget _scoreCell(int? strokes, int par, ThemeData theme) {
    if (strokes == null) {
      return _valueCell('-', theme);
    }
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

  Widget _totalCell(int? total, int par, ThemeData theme) {
    final diff = total != null ? total - par : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            total?.toString() ?? '-',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (diff != null)
            Text(
              diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff'),
              style: TextStyle(
                fontSize: 11,
                color: diff < 0
                    ? AppColors.birdie
                    : diff == 0
                        ? AppColors.par
                        : AppColors.bogey,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 72, color: AppColors.greenLight),
          const SizedBox(height: 16),
          Text('No rounds yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Completed rounds will appear here',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
