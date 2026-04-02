import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/player.dart';
import '../models/round.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'djgolfcard.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        holes_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE rounds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        player_ids_json TEXT NOT NULL,
        scores_json TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses(id)
      )
    ''');
  }

  // -- Courses --

  Future<int> insertCourse(Course course) async {
    final db = await database;
    final holesJson = jsonEncode(course.holes.map((h) => h.toMap()).toList());
    return db.insert('courses', {'name': course.name, 'holes_json': holesJson});
  }

  Future<List<Course>> getCourses() async {
    final db = await database;
    final rows = await db.query('courses', orderBy: 'name ASC');
    return rows.map((row) {
      final holes = (jsonDecode(row['holes_json'] as String) as List)
          .map((h) => Hole.fromMap(Map<String, dynamic>.from(h as Map)))
          .toList();
      return Course(
          id: row['id'] as int, name: row['name'] as String, holes: holes);
    }).toList();
  }

  Future<void> updateCourse(Course course) async {
    final db = await database;
    final holesJson = jsonEncode(course.holes.map((h) => h.toMap()).toList());
    await db.update(
      'courses',
      {'name': course.name, 'holes_json': holesJson},
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<void> deleteCourse(int id) async {
    final db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // -- Players --

  Future<int> insertPlayer(Player player) async {
    final db = await database;
    return db.insert('players', {'name': player.name});
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final rows = await db.query('players', orderBy: 'name ASC');
    return rows
        .map((r) => Player.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> deletePlayer(int id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // -- Rounds --

  Future<int> insertRound(Round round) async {
    final db = await database;
    final playerIds = round.players.map((p) => p.id).toList();
    final scoresMap = round.scores.map((holeNum, hs) => MapEntry(
          holeNum.toString(),
          hs.strokes.map((pid, s) => MapEntry(pid.toString(), s)),
        ));
    return db.insert('rounds', {
      'course_id': round.course.id,
      'date': round.date.toIso8601String(),
      'player_ids_json': jsonEncode(playerIds),
      'scores_json': jsonEncode(scoresMap),
    });
  }

  Future<void> updateRoundScores(Round round) async {
    final db = await database;
    final scoresMap = round.scores.map((holeNum, hs) => MapEntry(
          holeNum.toString(),
          hs.strokes.map((pid, s) => MapEntry(pid.toString(), s)),
        ));
    await db.update(
      'rounds',
      {'scores_json': jsonEncode(scoresMap)},
      where: 'id = ?',
      whereArgs: [round.id],
    );
  }

  Future<List<Round>> getRounds(
      List<Course> courses, List<Player> players) async {
    final db = await database;
    final rows = await db.query('rounds', orderBy: 'date DESC');
    final courseMap = {for (final c in courses) c.id!: c};
    final playerMap = {for (final p in players) p.id!: p};

    return rows.map((row) {
      final course = courseMap[row['course_id'] as int]!;
      final playerIds = (jsonDecode(row['player_ids_json'] as String) as List)
          .map((id) => id as int)
          .toList();
      final roundPlayers = playerIds.map((id) => playerMap[id]!).toList();

      final rawScores =
          jsonDecode(row['scores_json'] as String) as Map<String, dynamic>;
      final scoresMap = <int, HoleScore>{};
      for (final hole in course.holes) {
        final holeKey = hole.number.toString();
        final strokeMap = rawScores[holeKey] as Map<String, dynamic>? ?? {};
        final strokes = <int, int?>{
          for (final p in roundPlayers)
            p.id!: strokeMap[p.id.toString()] as int?,
        };
        scoresMap[hole.number] = HoleScore(
          holeNumber: hole.number,
          par: hole.par,
          strokes: strokes,
        );
      }

      return Round(
        id: row['id'] as int,
        course: course,
        players: roundPlayers,
        date: DateTime.parse(row['date'] as String),
        scores: scoresMap,
      );
    }).toList();
  }

  Future<void> deleteRound(int id) async {
    final db = await database;
    await db.delete('rounds', where: 'id = ?', whereArgs: [id]);
  }
}
