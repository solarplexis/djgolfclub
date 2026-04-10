import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/round_provider.dart';
import '../../theme/app_theme.dart';
import 'scorecard_screen.dart';

class RoundScreen extends StatelessWidget {
  final Course? initialCourse;
  const RoundScreen({super.key, this.initialCourse});

  @override
  Widget build(BuildContext context) {
    final activeRound = context.watch<RoundProvider>().activeRound;

    if (activeRound != null) {
      return const ScorecardScreen();
    }
    return _StartRoundScreen(initialCourse: initialCourse);
  }
}

class _StartRoundScreen extends StatefulWidget {
  final Course? initialCourse;
  const _StartRoundScreen({this.initialCourse});

  @override
  State<_StartRoundScreen> createState() => _StartRoundScreenState();
}

class _StartRoundScreenState extends State<_StartRoundScreen> {
  Course? _selectedCourse;
  final List<int> _orderedPlayerIds = [];
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.initialCourse;
  }

  Future<void> _startRound() async {
    if (_selectedCourse == null || _orderedPlayerIds.isEmpty) return;
    setState(() => _starting = true);
    final providerPlayers = context.read<PlayerProvider>().players;
    final players = _orderedPlayerIds
        .map((id) => providerPlayers.firstWhere((p) => p.id == id))
        .toList();
    await context.read<RoundProvider>().startRound(_selectedCourse!, players);
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = context.watch<CourseProvider>().courses;
    final players = context.watch<PlayerProvider>().players;
    final unselected =
        players.where((p) => !_orderedPlayerIds.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('NEW ROUND')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Course dropdown
          Text('SELECT COURSE', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (courses.isEmpty)
            Text(
              'No courses yet. Add one in the Courses tab.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            )
          else
            DropdownButtonFormField<Course>(
              value: _selectedCourse,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.golf_course),
                hintText: 'Choose a course…',
              ),
              items: courses
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.name}  ·  ${c.holeCount} holes  ·  Par ${c.totalPar}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCourse = val),
            ),
          const SizedBox(height: 24),

          // Player picker
          Text('SELECT PLAYERS', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (players.isEmpty)
            Text(
              'No players yet. Add some in the Players tab.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            )
          else ...[
            if (unselected.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey(unselected.map((p) => p.id).join(',')),
                value: null,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_add_outlined),
                  hintText: 'Add a player…',
                ),
                items: unselected
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id != null) setState(() => _orderedPlayerIds.add(id));
                },
              ),
            if (_orderedPlayerIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...List.generate(_orderedPlayerIds.length, (i) {
                final player =
                    players.firstWhere((p) => p.id == _orderedPlayerIds[i]);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.green,
                    radius: 16,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  title: Text(player.name, style: theme.textTheme.bodyLarge),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: i == 0
                            ? null
                            : () => setState(() {
                                  final id = _orderedPlayerIds.removeAt(i);
                                  _orderedPlayerIds.insert(i - 1, id);
                                }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: i == _orderedPlayerIds.length - 1
                            ? null
                            : () => setState(() {
                                  final id = _orderedPlayerIds.removeAt(i);
                                  _orderedPlayerIds.insert(i + 1, id);
                                }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 20),
                        onPressed: () =>
                            setState(() => _orderedPlayerIds.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedCourse == null ||
                      _orderedPlayerIds.isEmpty ||
                      _starting)
                  ? null
                  : _startRound,
              child: _starting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : const Text('TEE OFF'),
            ),
          ),
        ],
      ),
    );
  }
}
