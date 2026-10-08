import '../../core/display_text.dart';

import 'package:flutter/material.dart';

import '../../models/student_analytics.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  final int courseId;
  final String? courseName;

  const StudentAnalyticsScreen({
    super.key,
    required this.courseId,
    this.courseName,
  });

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  late Future<StudentAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _analyticsFuture = _apiService.getStudentCourseAnalytics(
        courseId: widget.courseId,
      );
    });
  }

  Widget _buildRiskChip(String? riskLevel, double? riskScore) {
    if (riskLevel == null && riskScore == null) {
      return const Chip(
        label: Text('Mức nguy cơ: Chưa có dữ liệu'),
        backgroundColor: Color(0xFFF1F5F9),
      );
    }

    final levelUpper = riskLevel?.toUpperCase() ?? '';
    Color color;
    Color textColor;
    String displayLevel;

    if (levelUpper.contains('HIGH') || levelUpper.contains('CAO')) {
      color = Colors.red.shade100;
      textColor = Colors.red.shade900;
      displayLevel = 'Nguy cơ cao';
    } else if (levelUpper.contains('MEDIUM') ||
        levelUpper.contains('TRUNG BÌNH')) {
      color = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
      displayLevel = 'Nguy cơ trung bình';
    } else if (levelUpper.contains('LOW') || levelUpper.contains('THẤP')) {
      color = Colors.green.shade100;
      textColor = Colors.green.shade900;
      displayLevel = 'Nguy cơ thấp';
    } else {
      color = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
      displayLevel = 'Chưa có mức nguy cơ';
    }

    final labelText =
        'Mức nguy cơ: $displayLevel'
        '${riskScore != null ? ' (${vietnameseDecimal(riskScore)})' : ''}';

    return Chip(
      avatar: Icon(Icons.shield_outlined, size: 18, color: textColor),
      label: Text(
        labelText,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }

  String _formatVal(dynamic val, {String suffix = ''}) {
    if (val == null) return 'Chưa có dữ liệu';
    if (val is double) {
      return '${vietnameseDecimal(val)}$suffix';
    }
    return '$val$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DemoDisplayNames.course(widget.courseName ?? 'Phân tích học tập'),
        ),
      ),
      body: FutureBuilder<StudentAnalytics>(
        future: _analyticsFuture,
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
                      onPressed: _loadAnalytics,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final analytics = snapshot.data;
          if (analytics == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final displayName =
              analytics.courseName ?? widget.courseName ?? 'Chi tiết khóa học';

          final attendanceValText = analytics.attendancePercentage != null
              ? '${vietnameseDecimal(analytics.attendancePercentage!)}%'
              : 'Chưa có dữ liệu chuyên cần';

          return RefreshIndicator(
            onRefresh: () async {
              _loadAnalytics();
              await _analyticsFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Risk Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DemoDisplayNames.course(displayName),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRiskChip(
                            analytics.riskLevel,
                            analytics.riskScore,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Chỉ số học tập cá nhân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  MetricCard(
                    title: 'Tiến độ học tập',
                    value: _formatVal(
                      analytics.progressPercentage,
                      suffix: '%',
                    ),
                    icon: Icons.trending_up_rounded,
                    iconColor: Colors.blue,
                  ),
                  MetricCard(
                    title: 'Điểm TB hoạt động đã chấm',
                    value: _formatVal(
                      analytics.averageGradePercentage,
                      suffix: '%',
                    ),
                    icon: Icons.grade_rounded,
                    iconColor: Colors.amber.shade800,
                  ),
                  MetricCard(
                    title: 'Tỷ lệ chuyên cần',
                    value: attendanceValText,
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: Colors.teal,
                  ),
                  MetricCard(
                    title: 'Bài tập đã hoàn thành',
                    value: _formatVal(analytics.completedTasks),
                    icon: Icons.task_alt_rounded,
                    iconColor: Colors.green,
                  ),
                  MetricCard(
                    title: 'Bài tập chưa hoàn thành',
                    value: _formatVal(analytics.pendingTasks),
                    icon: Icons.pending_actions_rounded,
                    iconColor: Colors.orange,
                  ),
                  MetricCard(
                    title: 'Bài tập đã quá hạn',
                    value: _formatVal(analytics.overdueTasks),
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red,
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Tương tác & Hoạt động (7 ngày qua)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  MetricCard(
                    title: 'Sự kiện tương tác',
                    value: _formatVal(analytics.eventsLast7Days),
                    icon: Icons.touch_app_rounded,
                    iconColor: Colors.indigo,
                  ),
                  MetricCard(
                    title: 'Số ngày tương tác',
                    value: _formatVal(
                      analytics.activeDaysLast7Days,
                      suffix: ' ngày',
                    ),
                    icon: Icons.calendar_today_rounded,
                    iconColor: Colors.purple,
                  ),
                  MetricCard(
                    title: 'Số ngày từ lần tương tác cuối',
                    value: _formatVal(
                      analytics.daysSinceLastActivity,
                      suffix: ' ngày',
                    ),
                    icon: Icons.history_rounded,
                    iconColor: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
