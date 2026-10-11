import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/class_insights.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';
import 'teacher_notes_screen.dart';

class TeacherAnalyticsTab extends StatefulWidget {
  final int courseId;
  final String? courseName;
  final ApiService? api;
  final VoidCallback? onHighRisk;

  const TeacherAnalyticsTab({
    super.key,
    required this.courseId,
    this.courseName,
    this.api,
    this.onHighRisk,
  });

  @override
  State<TeacherAnalyticsTab> createState() => _TeacherAnalyticsTabState();
}

class _TeacherAnalyticsTabState extends State<TeacherAnalyticsTab> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<ClassInsights> _insightsFuture;
  int _selectedWeeks = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _insightsFuture = _api.getClassInsights(courseId: widget.courseId, weeks: _selectedWeeks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            children: [
              const Text('Khung thời gian: '),
              DropdownButton<int>(
                value: _selectedWeeks,
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 tuần')),
                  DropdownMenuItem(value: 8, child: Text('8 tuần')),
                  DropdownMenuItem(value: 12, child: Text('12 tuần')),
                  DropdownMenuItem(value: 16, child: Text('16 tuần')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedWeeks = val;
                      _loadData();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<ClassInsights>(
        future: _insightsFuture,
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

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _insightsFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(data),
                  const SizedBox(height: 24),
                  _buildWatchGroupsChart(data.groups),
                  const SizedBox(height: 24),
                  _buildWeeklyTrendChart(data.weekly),
                  const SizedBox(height: 24),
                  _buildTaskStatusPieChart(data.tasks),
                  const SizedBox(height: 24),
                  _buildAttentionStudents(data.attention),
                  const SizedBox(height: 24),
                  _buildInterventions(data.interventions),
                ],
              ),
            ),
          );
        },
      ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(ClassInsights data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        MetricCard(
          title: 'Tổng sinh viên',
          value: '${data.studentCount}',
          icon: Icons.people,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
        MetricCard(
          title: 'Cần chú ý',
          value: '${data.watchCount}',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
        ),
        MetricCard(
          title: 'Tiến độ TB',
          value: data.averageProgress != null ? '${data.averageProgress!.toStringAsFixed(1)}%' : '--',
          icon: Icons.trending_up,
          iconColor: Colors.green,
        ),
        MetricCard(
          title: 'Điểm TB',
          value: data.averageGrade != null ? '${data.averageGrade!.toStringAsFixed(1)}%' : '--',
          icon: Icons.grade,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildWatchGroupsChart(WatchGroups groups) {
    if (groups.total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân nhóm sinh viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Đánh giá mức độ hoàn thành và sự tham gia của sinh viên trong khóa học.',
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
                          if (groups.onTrack > 0)
                            PieChartSectionData(
                              color: Colors.green,
                              value: groups.onTrack.toDouble(),
                              title: '${groups.onTrack}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (groups.watch > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: groups.watch.toDouble(),
                              title: '${groups.watch}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (groups.needsSupport > 0)
                            PieChartSectionData(
                              color: Colors.red,
                              value: groups.needsSupport.toDouble(),
                              title: '${groups.needsSupport}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (groups.unknown > 0)
                            PieChartSectionData(
                              color: Colors.grey,
                              value: groups.unknown.toDouble(),
                              title: '${groups.unknown}',
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendItem(color: Colors.green, text: 'Đúng tiến độ'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.orange, text: 'Cần theo dõi'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.red, text: 'Cần hỗ trợ'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.grey, text: 'Không rõ'),
                    ],
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(WeeklyTrend trend) {
    if (trend.points.isEmpty) return const SizedBox.shrink();

    final points = trend.points;
    final List<FlSpot> activeSpots = [];
    final List<FlSpot> completedSpots = [];
    double maxY = 0;

    for (int i = 0; i < points.length; i++) {
      final active = points[i].activeStudents.toDouble();
      final completed = points[i].completed.toDouble();
      if (active > maxY) maxY = active;
      if (completed > maxY) maxY = completed;
      activeSpots.add(FlSpot(i.toDouble(), active));
      completedSpots.add(FlSpot(i.toDouble(), completed));
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
              'Xu hướng tuần',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Biến động số lượng sinh viên hoạt động và bài tập hoàn thành qua từng tuần.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
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
                      spots: activeSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: completedSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(color: Theme.of(context).colorScheme.primary, text: 'SV Hoạt động'),
                const _LegendItem(color: Colors.green, text: 'HĐ Hoàn thành'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionStudents(List<AttentionStudent> students) {
    if (students.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sinh viên cần chú ý',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Danh sách các sinh viên có tiến độ kém hoặc quá hạn nhiều bài tập.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        if (widget.onHighRisk != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: widget.onHighRisk,
              child: const Text('Xem sinh viên cần theo dõi'),
            ),
          ),
        ...students.map((s) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.person, color: Colors.orange, size: 32),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tiến độ: ${(s.progress ?? 0).toStringAsFixed(1)}% | Quá hạn: ${s.overdue ?? 0}'),
              children: [
                if (s.reasons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lý do:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...s.reasons.map((r) => Text('• $r')),
                      ],
                    ),
                  ),
                if (s.actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hành động đề xuất:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...s.actions.map((a) => Text('• $a', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Ghi chú hỗ trợ'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherNotesScreen(
                            api: _api,
                            studentId: s.id,
                            studentName: s.name,
                            courseId: widget.courseId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaskStatusPieChart(ClassTaskStatus status) {
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
              'Trạng thái bài tập của lớp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Phân bố trạng thái của tất cả lượt giao bài trong khóa học.',
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
                  Expanded(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendItem(color: Colors.green, text: 'Đã nộp/Hoàn thành'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.orange, text: 'Chưa nộp'),
                      SizedBox(height: 8),
                      _LegendItem(color: Colors.red, text: 'Quá hạn'),
                    ],
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventions(List<Intervention> interventions) {
    if (interventions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đề xuất can thiệp',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Các hành động gợi ý để cải thiện chất lượng học tập của lớp.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ...interventions.map((i) {
          final dateStr = i.createdAt != null 
              ? '${i.createdAt!.hour.toString().padLeft(2,'0')}:${i.createdAt!.minute.toString().padLeft(2,'0')} ${i.createdAt!.day}/${i.createdAt!.month}'
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 32),
              title: Text(i.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(i.reason),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
