import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/course.dart';
import '../models/player.dart';
import '../models/round.dart';

class RoundProvider extends ChangeNotifier {
  List<Round> _history = [];
  Round? _activeRound;

  List<Round> get history => _history;
  Round? get activeRound => _activeRound;

  Future<void> load() async {
    final courses = await DatabaseHelper.instance.getCourses();
    final players = await DatabaseHelper.instance.getPlayers();
    _history = await DatabaseHelper.instance.getRounds(courses, players);
    notifyListeners();
  }

  // Keep old signature for any call sites that still pass arguments.
  Future<void> loadHistory(dynamic courses, dynamic players) => load();

  Future<void> startRound(Course course, List<Player> players) async {
    final round = Round(
      course: course,
      players: players,
      date: DateTime.now(),
    );
    final id = await DatabaseHelper.instance.insertRound(round);
    _activeRound = Round(
      id: id,
      course: course,
      players: players,
      date: round.date,
      scores: round.scores,
    );
    notifyListeners();
  }

  Future<void> updateScore(int holeNumber, int playerId, int strokes) async {
    if (_activeRound == null) return;
    final hs = _activeRound!.scores[holeNumber]!;
    final updatedStrokes = {...hs.strokes, playerId: strokes};
    final updatedHs = HoleScore(
      holeNumber: hs.holeNumber,
      par: hs.par,
      strokes: updatedStrokes,
    );
    final updatedScores = {..._activeRound!.scores, holeNumber: updatedHs};
    _activeRound = Round(
      id: _activeRound!.id,
      course: _activeRound!.course,
      players: _activeRound!.players,
      date: _activeRound!.date,
      scores: updatedScores,
    );
    await DatabaseHelper.instance.updateRoundScores(_activeRound!);
    notifyListeners();
  }

  Future<void> finishRound([dynamic courses, dynamic players]) async {
    if (_activeRound == null) return;
    _history.insert(0, _activeRound!);
    _activeRound = null;
    notifyListeners();
  }

  void abandonRound() {
    if (_activeRound?.id != null) {
      DatabaseHelper.instance.deleteRound(_activeRound!.id!);
    }
    _activeRound = null;
    notifyListeners();
  }

  Future<void> deleteRound(int id) async {
    await DatabaseHelper.instance.deleteRound(id);
    _history = _history.where((r) => r.id != id).toList();
    notifyListeners();
  }
}
