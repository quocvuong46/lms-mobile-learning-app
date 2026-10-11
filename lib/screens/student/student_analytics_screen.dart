import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/student_insights.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/learning_widgets.dart';
import 'student_goals_screen.dart';
import 'student_flashcard_screen.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  final ApiService? apiService;
  const StudentAnalyticsScreen({super.key, this.apiService});

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        _api.getGlobalStudentInsights(),
        _api.getReflections(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích Học tập'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data;
          if (results == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }
          
          final data = results[0] as StudentInsights;
          final reflections = results[1] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _dataFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(data.summary, data.streak),
                  const SizedBox(height: 16),
                  _buildGoalSection(data.summary),
                  const SizedBox(height: 24),
                  _buildProgressTimelineChart(data.timeline),
                  const SizedBox(height: 24),
                  _buildHeatmap(data.heatmap),
                  const SizedBox(height: 24),
                  _buildTaskStatusPieChart(data.taskStatus),
                  const SizedBox(height: 24),
                  _buildSuggestions(data.suggestions, reflections),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(InsightsSummary summary, StreakInfo streak) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        MetricCard(
          title: 'Khóa học',
          value: '${summary.courseCount ?? 0}',
          icon: Icons.school,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
        MetricCard(
          title: 'Chuỗi học',
          value: '${streak.currentDays} ngày',
          icon: Icons.local_fire_department,
          iconColor: Colors.orange,
        ),
        MetricCard(
          title: 'Tiến độ TB',
          value: '${(summary.averageProgress ?? 0).toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          iconColor: Colors.green,
        ),
        MetricCard(
          title: 'Ngày HĐ',
          value: '${summary.activeDays ?? 0}',
          icon: Icons.calendar_today,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildGoalSection(InsightsSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.flag_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mục tiêu học tập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${summary.activeGoals ?? 0} đang HĐ • ${summary.achievedGoals ?? 0} đã đạt', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StudentGoalsScreen(api: _api)));
                  },
                  child: const Text('Quản lý'),
                ),
              ],
            ),
            if ((summary.dueSoonGoals ?? 0) > 0) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Có ${summary.dueSoonGoals} mục tiêu sắp đến hạn cần chú ý!', 
                      style: const TextStyle(color: Colors.orange, fontSize: 13)
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimelineChart(ProgressTimeline timeline) {
    if (!timeline.available || timeline.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = timeline.points;
    final List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < points.length; i++) {
      final val = points[i].completedInWeek.toDouble();
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (maxY == 0) maxY = 5;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiến độ hoàn thành bài tập (Theo tuần)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Số lượng bài tập hoàn thành mỗi tuần trong khoảng thời gian vừa qua.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < points.length) {
                            final date = points[idx].weekStart;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY + (maxY * 0.2),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusPieChart(TaskStatusSummary status) {
    if (status.total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái bài tập',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tỷ lệ phân bố trạng thái các bài tập và nhiệm vụ của bạn.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (status.completed > 0)
                            PieChartSectionData(
                              color: Colors.green,
                              value: status.completed.toDouble(),
                              title: '${status.completed}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (status.pending > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: status.pending.toDouble(),
                              title: '${status.pending}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (status.overdue > 0)
                            PieChartSectionData(
                              color: Colors.red,
                              value: status.overdue.toDouble(),
                              title: '${status.overdue}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendItem(color: Colors.green, text: 'Hoàn thành'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.orange, text: 'Chưa nộp'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.red, text: 'Quá hạn'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(ActivityHeatmap heatmap) {
    if (!heatmap.hasData || heatmap.days.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ hoạt động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Số lượng hoạt động mỗi ngày. Càng đậm nghĩa là càng nhiều hoạt động.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140, // 7 rows approx 20px each
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: heatmap.days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final day = heatmap.days[index];
                  double opacity = 0.1;
                  if (day.events > 0) {
                    opacity = (day.events / (heatmap.maxEvents > 0 ? heatmap.maxEvents : 1)).clamp(0.2, 1.0);
                  }
                  
                  return Tooltip(
                    message: '${day.date.day}/${day.date.month}: ${day.events} hoạt động',
                    child: Container(
                      decoration: BoxDecoration(
                        color: day.events > 0 
                            ? Colors.green.withValues(alpha: opacity)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Ít', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 4),
                for (double i = 0.1; i <= 1.0; i += 0.25)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: i == 0.1 ? Colors.grey.withValues(alpha: 0.1) : Colors.green.withValues(alpha: i),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                const SizedBox(width: 4),
                const Text('Nhiều', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(List<InsightSuggestion> suggestions, List<Map<String, dynamic>> reflections) {
    final weakReflections = reflections.where((r) => (r['understanding_level'] ?? 5) <= 2).toList();
    
    final allSuggestions = List<InsightSuggestion>.from(suggestions);
    if (weakReflections.isNotEmpty) {
      allSuggestions.insert(0, InsightSuggestion.fromJson({
        'title': 'Cần ôn tập Flashcard',
        'reason': 'Bạn có ${weakReflections.length} nội dung chưa hiểu rõ. Hãy dùng Flashcard để củng cố kiến thức.',
        'severity': 'medium',
      }));
    }

    if (allSuggestions.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý & Hành động',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          EmptyState('Hiện tại bạn đang học rất tốt, không có vấn đề nào cần chú ý!'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gợi ý & Hành động',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Dựa trên phân tích hoạt động, dưới đây là những điều bạn nên chú ý.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ...allSuggestions.map((s) {
          IconData icon;
          Color color;
          switch (s.severity) {
            case 'high':
            case 'attention':
              icon = Icons.warning_rounded;
              color = Colors.red;
              break;
            case 'medium':
              icon = Icons.info_outline;
              color = Colors.orange;
              break;
            case 'positive':
              icon = Icons.check_circle_outline;
              color = Colors.green;
              break;
            default:
              icon = Icons.lightbulb_outline;
              color = Theme.of(context).colorScheme.primary;
          }

          final dateStr = s.createdAt != null 
              ? '${s.createdAt!.hour.toString().padLeft(2,'0')}:${s.createdAt!.minute.toString().padLeft(2,'0')} ${s.createdAt!.day}/${s.createdAt!.month}'
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(icon, color: color, size: 32),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(s.reason),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Tạo lúc: $dateStr',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
              isThreeLine: dateStr.isNotEmpty,
              onTap: s.title == 'Cần ôn tập Flashcard'
                  ? () {
                      int targetCourseId = 0; // fallback
                      if (weakReflections.isNotEmpty) {
                         targetCourseId = int.tryParse(weakReflections.first['course_id']?.toString() ?? '0') ?? 0;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentFlashcardScreen(
                            api: _api,
                            courseId: targetCourseId,
                            courseName: 'Ôn tập Kiến thức',
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
