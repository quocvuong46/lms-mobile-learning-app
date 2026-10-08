import '../../core/display_text.dart';

import 'package:flutter/material.dart';

import '../../models/teacher_analytics.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  final int courseId;
  final String? courseName;
  const TeacherAnalyticsScreen({
    super.key,
    required this.courseId,
    this.courseName,
  });

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  final _api = ApiService();
  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        DemoDisplayNames.course(widget.courseName ?? 'Phân tích giảng dạy'),
      ),
    ),
    body: TeacherAnalyticsTab(api: _api, courseId: widget.courseId),
  );
}

class TeacherAnalyticsTab extends StatelessWidget {
  final VoidCallback? onHighRisk;
  final ApiService api;
  final int courseId;
  const TeacherAnalyticsTab({
    super.key,
    required this.api,
    required this.courseId,
    this.onHighRisk,
  });

  @override
  Widget build(BuildContext context) => AsyncTab<TeacherAnalytics>(
    load: () => api.getTeacherCourseAnalytics(courseId: courseId),
    children: (data) => [
      DetailCard(
        title: 'Sinh viên cần hỗ trợ',
        children: [
          DetailLine(
            'Sinh viên nguy cơ cao',
            detailValue(data.highRiskStudents),
          ),
          DetailLine(
            'Sinh viên nguy cơ trung bình',
            detailValue(data.mediumRiskStudents),
          ),
          DetailLine(
            'Sinh viên nguy cơ thấp',
            detailValue(data.lowRiskStudents),
          ),
          if (onHighRisk != null) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onHighRisk,
              icon: const Icon(Icons.people_outline),
              label: const Text('Xem sinh viên cần hỗ trợ'),
            ),
            const SizedBox(height: 4),
            Text(
              'Ưu tiên sinh viên nguy cơ cao',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      DetailCard(
        title: 'Chỉ số trung bình lớp học',
        children: [
          DetailLine('Số sinh viên', detailValue(data.studentCount)),
          DetailLine(
            'Tiến độ trung bình',
            detailValue(data.averageProgress, suffix: '%'),
          ),
          DetailLine(
            'Trung bình các hoạt động đã chấm',
            detailValue(data.averageGrade, suffix: '%'),
          ),
          DetailLine(
            'Chuyên cần trung bình',
            detailValue(data.averageAttendancePercentage, suffix: '%'),
          ),
        ],
      ),
      DetailCard(
        title: 'Mức tương tác trung bình',
        children: [
          Text(
            'Tính trên mỗi sinh viên trong 7 ngày qua.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            data.averageEventsLast7Days == null
                ? 'Chưa có dữ liệu'
                : 'Trung bình: ${vietnameseDecimal(data.averageEventsLast7Days!, digits: data.averageEventsLast7Days! % 1 == 0 ? 0 : 1)} tương tác',
          ),
          Text(
            data.averageActiveDaysLast7Days == null
                ? 'Chưa có dữ liệu'
                : 'Trung bình: ${vietnameseDecimal(data.averageActiveDaysLast7Days!, digits: data.averageActiveDaysLast7Days! % 1 == 0 ? 0 : 1)} ngày hoạt động',
          ),
        ],
      ),
      DetailCard(
        title: 'Việc cần làm của lớp',
        children: [
          DetailLine(
            'Chưa hoàn thành, chưa quá hạn',
            detailValue(data.pendingTasks),
          ),
          DetailLine('Đã quá hạn', detailValue(data.overdueTasks)),
        ],
      ),
    ],
  );
}
