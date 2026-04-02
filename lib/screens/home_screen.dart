import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/round_provider.dart';
import 'courses/courses_screen.dart';
import 'players/players_screen.dart';
import 'round/round_screen.dart';
import 'history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _CoursesTab(),
    _PlayersTab(),
    _RoundTab(),
    _HistoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeRound = context.watch<RoundProvider>().activeRound;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.golf_course),
            label: 'Courses',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Players',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeRound != null,
              child: const Icon(Icons.sports_golf),
            ),
            label: 'Round',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab();
  @override
  Widget build(BuildContext context) => const CoursesScreen();
}

class _PlayersTab extends StatelessWidget {
  const _PlayersTab();
  @override
  Widget build(BuildContext context) => const PlayersScreen();
}

class _RoundTab extends StatelessWidget {
  const _RoundTab();
  @override
  Widget build(BuildContext context) => const RoundScreen();
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) => const HistoryScreen();
}
