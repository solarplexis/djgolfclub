import 'course.dart';
import 'player.dart';

class HoleScore {
  final int holeNumber;
  final int par;
  // playerId -> strokes (null = not yet entered)
  final Map<int, int?> strokes;

  HoleScore(
      {required this.holeNumber, required this.par, required this.strokes});
}

class Round {
  final int? id;
  final Course course;
  final List<Player> players;
  final DateTime date;
  // holeNumber -> HoleScore
  final Map<int, HoleScore> scores;

  Round({
    this.id,
    required this.course,
    required this.players,
    required this.date,
    Map<int, HoleScore>? scores,
  }) : scores = scores ??
            {
              for (final hole in course.holes)
                hole.number: HoleScore(
                  holeNumber: hole.number,
                  par: hole.par,
                  strokes: {for (final p in players) p.id!: null},
                )
            };

  /// Sum of strokes entered so far for [player]. Reflects whatever holes
  /// have actually been played rather than requiring the whole course —
  /// a player who only plays the front 9 still gets a total for those
  /// 9 holes.
  int? totalFor(Player player) => partialTotalFor(player, scores.keys);

  /// Sum of strokes entered so far for [player] across [holeNumbers].
  /// Used to show running Front 9 / Back 9 subtotals mid-round.
  int? partialTotalFor(Player player, Iterable<int> holeNumbers) {
    int total = 0;
    bool any = false;
    for (final holeNumber in holeNumbers) {
      final s = scores[holeNumber]?.strokes[player.id];
      if (s != null) {
        total += s;
        any = true;
      }
    }
    return any ? total : null;
  }

  /// Sum of par for the holes [player] has actually recorded strokes for.
  /// Used instead of [course.totalPar] so a partial round (e.g. front 9
  /// only) shows an accurate over/under par instead of comparing against
  /// the full course's par.
  int parThroughFor(Player player) {
    int total = 0;
    for (final hole in course.holes) {
      if (scores[hole.number]?.strokes[player.id] != null) {
        total += hole.par;
      }
    }
    return total;
  }

  /// True once every hole in the course has a score for every player.
  bool get isComplete => scores.values.every(
        (hs) => hs.strokes.values.every((s) => s != null),
      );

  /// True once at least one hole has been fully scored for every player —
  /// enough to let the round be finished early (e.g. after just the
  /// front 9) instead of requiring the whole course.
  bool get anyHoleComplete => scores.values.any(
        (hs) => hs.strokes.values.every((s) => s != null),
      );
}
