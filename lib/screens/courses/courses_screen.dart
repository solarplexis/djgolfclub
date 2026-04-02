import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_theme.dart';
import 'create_course_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COURSES'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.courses.isEmpty
              ? _EmptyState(onAdd: () => _openCreate(context))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: provider.courses.length,
                  itemBuilder: (ctx, i) =>
                      _CourseCard(course: provider.courses[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context),
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          course.name.toUpperCase(),
          style: theme.textTheme.titleLarge,
        ),
        subtitle: Text(
          '${course.holeCount} holes · Par ${course.totalPar}',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PAR ${course.totalPar}',
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: () => _openEdit(context),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.textMuted),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateCourseScreen(course: course)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Remove "${course.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CourseProvider>().deleteCourse(course.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.golf_course, size: 72, color: AppColors.greenLight),
          const SizedBox(height: 16),
          Text('No courses yet', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Add your first course below',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('ADD COURSE'),
          ),
        ],
      ),
    );
  }
}
