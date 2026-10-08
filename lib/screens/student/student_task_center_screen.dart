import 'package:flutter/material.dart';

import '../../models/student_course_detail.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';

enum TaskFilter { all, pending, soon, overdue, done }

List<StudentTask> filterTasks(
  List<StudentTask> tasks,
  TaskFilter filter,
  DateTime now,
) => StudentTask.sorted(
  tasks
      .where(
        (t) => switch (filter) {
          TaskFilter.all => true,
          TaskFilter.pending => t.isPending,
          TaskFilter.soon => t.isDueSoon(now),
          TaskFilter.overdue => t.isOverdue(now),
          TaskFilter.done => t.isDone,
        },
      )
      .toList(),
  now,
);

class StudentTaskCenterScreen extends StatefulWidget {
  final ApiService api;
  final bool reminders;
  const StudentTaskCenterScreen({
    super.key,
    required this.api,
    this.reminders = false,
  });
  @override
  State<StudentTaskCenterScreen> createState() =>
      _StudentTaskCenterScreenState();
}

class _StudentTaskCenterScreenState extends State<StudentTaskCenterScreen> {
  TaskFilter _filter = TaskFilter.all;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.reminders ? 'Nhắc hạn học tập' : 'Việc cần làm'),
    ),
    body: AsyncTab<List<StudentTask>>(
      load: widget.api.getAllStudentTasks,
      children: (tasks) {
        final now = DateTime.now();
        final visible = widget.reminders
            ? StudentTask.sorted(
                tasks
                    .where((t) => t.isOverdue(now) || t.isDueSoon(now))
                    .toList(),
                now,
              )
            : filterTasks(tasks, _filter, now);
        return [
          if (widget.reminders)
            const Text(
              'Tổng hợp từ hạn nộp trong các khóa học. Cập nhật khi tải lại.',
            ),
          if (!widget.reminders)
            LearningFilterBar(
              wrap: true,
              children: [
                for (final (filter, label) in [
                  (TaskFilter.all, 'Tất cả'),
                  (TaskFilter.pending, 'Chưa làm'),
                  (TaskFilter.soon, 'Sắp hạn'),
                  (TaskFilter.overdue, 'Quá hạn'),
                  (TaskFilter.done, 'Đã xong'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            EmptyState(
              widget.reminders
                  ? 'Bạn chưa có việc sắp hạn hoặc quá hạn'
                  : !tasks.any((t) => t.isPending) &&
                        (_filter == TaskFilter.pending ||
                            _filter == TaskFilter.all)
                  ? 'Bạn đã hoàn thành tất cả việc cần làm'
                  : 'Không có việc trong bộ lọc này',
            ),
          ...visible.map(TaskCard.new),
        ];
      },
    ),
  );
}
