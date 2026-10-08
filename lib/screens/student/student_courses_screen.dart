import 'package:flutter/material.dart';

import '../../models/student_course.dart';
import '../../services/api_service.dart';
import '../../widgets/learning_widgets.dart';
import 'student_course_detail_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  final ApiService? apiService;
  const StudentCoursesScreen({super.key, this.apiService});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();
  late Future<List<StudentCourse>> _coursesFuture;

  @override
  void dispose() {
    if (widget.apiService == null) _apiService.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    setState(() {
      _coursesFuture = _apiService.getStudentCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khóa học')),
      body: FutureBuilder<List<StudentCourse>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Load screen: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải dữ liệu',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng thử lại',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadCourses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn chưa đăng ký khóa học nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadCourses();
              await _coursesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseProgressCard(
                  course: course,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentCourseDetailScreen(
                          course: course,
                          apiService: _apiService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
