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

  int? totalFor(Player player) {
    int total = 0;
    for (final hs in scores.values) {
      final s = hs.strokes[player.id];
      if (s == null) return null;
      total += s;
    }
    return total;
  }

  bool get isComplete => scores.values.every(
        (hs) => hs.strokes.values.every((s) => s != null),
      );
}
