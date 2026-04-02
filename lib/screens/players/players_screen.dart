import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import 'player_history_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<PlayerProvider>().addPlayer(name);
    _nameCtrl.clear();
  }

  Future<void> _confirmDelete(BuildContext context, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('REMOVE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PlayerProvider>().deletePlayer(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = context.watch<PlayerProvider>().players;

    return Scaffold(
      appBar: AppBar(title: const Text('PLAYERS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New player name',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Text(
                      'No players yet.\nAdd one above.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final p = players[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.green,
                          child: Text(
                            p.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(p.name, style: theme.textTheme.bodyLarge),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerHistoryScreen(player: p),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textMuted),
                          onPressed: () =>
                              _confirmDelete(context, p.id!, p.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
