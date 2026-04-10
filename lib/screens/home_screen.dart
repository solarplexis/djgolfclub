import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
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
  Course? _pendingCourse;

  void _startRoundWithCourse(Course course) {
    setState(() {
      _pendingCourse = course;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeRound = context.watch<RoundProvider>().activeRound;

    final tabs = [
      CoursesScreen(onStartRound: _startRoundWithCourse),
      const PlayersScreen(),
      RoundScreen(initialCourse: _pendingCourse),
      const HistoryScreen(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
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
