import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'student_dashboard_screen.dart';
import 'student_courses_screen.dart';
import 'student_task_center_screen.dart';
import 'student_analytics_screen.dart';
import '../notifications_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final ApiService? apiService;
  const StudentMainScreen({super.key, this.apiService});
  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  int _index = 0;
  final _visited = <int>{0};
  void _select(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });
  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        StudentDashboardScreen(
          apiService: _api,
          onTasks: () => _select(1),
          onCourses: () => _select(2),
        ),
        if (_visited.contains(1))
          StudentTaskCenterScreen(api: _api)
        else
          const SizedBox.shrink(),
        if (_visited.contains(2))
          StudentCoursesScreen(apiService: _api)
        else
          const SizedBox.shrink(),
        if (_visited.contains(3))
          NotificationsScreen(api: _api, onTasks: () => _select(1))
        else
          const SizedBox.shrink(),
        if (_visited.contains(4))
          StudentAnalyticsScreen(apiService: _api)
        else
          const SizedBox.shrink(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      height: 64 + 16 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist),
          label: 'Việc cần làm',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          label: 'Khóa học',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          label: 'Thông báo',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          label: 'Phân tích',
        ),
      ],
    ),
  );
}
