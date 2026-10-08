class LearningNotification {
  final String title;
  final String? message, courseName, moodlePath;
  final int? courseModuleId;
  final int? courseId, sourceId;
  final DateTime? time;
  final bool reminder;
  LearningNotification.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String? ?? 'Thông báo',
      message = j['message'] as String?,
      courseName = j['course_name'] as String?,
      moodlePath = j['moodle_path'] as String?,
      courseModuleId = (j['coursemoduleid'] as num?)?.toInt(),
      courseId = (j['course_id'] as num?)?.toInt(),
      sourceId = (j['source_id'] as num?)?.toInt(),
      time = j['event_time'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (j['event_time'] as num).toInt(),
            )
          : DateTime.tryParse(j['event_time']?.toString() ?? '')?.toLocal(),
      reminder = j['source_kind'] == 'reminder';
}
