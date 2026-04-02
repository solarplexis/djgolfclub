import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/player.dart';

class PlayerProvider extends ChangeNotifier {
  List<Player> _players = [];

  List<Player> get players => _players;

  Future<void> load() async {
    _players = await DatabaseHelper.instance.getPlayers();
    _players.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<Player> addPlayer(String name) async {
    final id = await DatabaseHelper.instance.insertPlayer(Player(name: name));
    final player = Player(id: id, name: name);
    _players = [..._players, player];
    _players.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return player;
  }

  Future<void> deletePlayer(int id) async {
    await DatabaseHelper.instance.deletePlayer(id);
    _players = _players.where((p) => p.id != id).toList();
    notifyListeners();
  }
}
