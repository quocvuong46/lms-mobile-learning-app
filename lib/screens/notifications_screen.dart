import '../core/display_text.dart';

import 'package:flutter/material.dart';

import '../models/learning_notification.dart';
import '../models/student_course_detail.dart';
import '../services/api_service.dart';
import '../widgets/async_tab.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/moodle_button.dart';
import 'student/student_task_center_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final ApiService api;
  final bool teacher;
  final VoidCallback? onTasks;
  const NotificationsScreen({
    super.key,
    required this.api,
    this.teacher = false,
    this.onTasks,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo')),
    body: AsyncTab<List<LearningNotification>>(
      load: () => api.getNotifications(teacher: teacher),
      children: (items) => [
        if (items.isEmpty)
          const EmptyState(
            'Bạn chưa có thông báo mới',
            subtitle: 'Kiểm tra Việc cần làm để theo dõi hạn nộp.',
          ),
        for (final item in items)
          DetailCard(
            title: item.title,
            children: [
              Wrap(
                children: [
                  StatusChip(item.reminder ? 'Nhắc nhở' : 'Thông báo'),
                ],
              ),
              if (item.courseName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DemoDisplayNames.course(item.courseName!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (item.message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(item.message!),
                ),
              if (item.time != null)
                Text(
                  formatDeadline(item.time),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (moodleActivityUri(item.moodlePath, item.courseModuleId) !=
                  null)
                MoodleButton(
                  path: item.moodlePath,
                  courseModuleId: item.courseModuleId,
                  compact: true,
                )
              else if (!teacher &&
                  (item.courseId != null || item.sourceId != null))
                TextButton.icon(
                  onPressed:
                      onTasks ??
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentTaskCenterScreen(api: api),
                        ),
                      ),
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Kiểm tra việc cần làm'),
                ),
            ],
          ),
      ],
    ),
  );
}
