import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/course.dart';

class CourseProvider extends ChangeNotifier {
  List<Course> _courses = [];
  bool _loading = false;

  List<Course> get courses => _courses;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _courses = await DatabaseHelper.instance.getCourses();
    _loading = false;
    notifyListeners();
  }

  Future<void> addCourse(Course course) async {
    final id = await DatabaseHelper.instance.insertCourse(course);
    _courses = [
      ..._courses,
      Course(id: id, name: course.name, holes: course.holes)
    ];
    _courses.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    await DatabaseHelper.instance.updateCourse(course);
    _courses = _courses.map((c) => c.id == course.id ? course : c).toList();
    _courses.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteCourse(int id) async {
    await DatabaseHelper.instance.deleteCourse(id);
    _courses = _courses.where((c) => c.id != id).toList();
    notifyListeners();
  }
}
