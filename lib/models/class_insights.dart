int? _int(dynamic v) => v is num ? v.toInt() : null;
double? _double(dynamic v) => v is num ? v.toDouble() : null;
String? _string(dynamic v) => v is String && v.trim().isNotEmpty ? v : null;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};
List<String> _strings(dynamic v) =>
    v is List ? v.whereType<String>().toList() : const [];

/// Typed view of GET /dev/teachers/{id}/courses/{id}/class-insights.
class ClassInsights {
  final DateTime? generatedAt;
  final bool isDemo;
  final String? dataNotice;
  final int weeks;
  final int studentCount, watchCount;
  final double? averageProgress, averageGrade;
  final List<BucketCount> progressDistribution;
  final WatchGroups groups;
  final List<String> criteria;
  final List<AttentionStudent> attention;
  final ClassTaskStatus tasks;
  final WeeklyTrend weekly;
  final List<LowCompletionActivity> lowActivities;
  final List<Intervention> interventions;

  ClassInsights.fromJson(Map<String, dynamic> j)
    : generatedAt = _date(j['generated_at']),
      isDemo = j['data_mode'] != 'live',
      dataNotice = _string(j['data_notice']),
      weeks = _int(j['weeks']) ?? 8,
      studentCount = _int(_map(j['summary'])['student_count']) ?? 0,
      watchCount = _int(_map(j['summary'])['watch_count']) ?? 0,
      averageProgress = _double(_map(j['summary'])['average_progress']),
      averageGrade = _double(_map(j['summary'])['average_grade_percentage']),
      progressDistribution = _maps(j['progress_distribution'])
          .map((m) => BucketCount(_string(m['label']) ?? '', _int(m['students']) ?? 0))
          .toList(),
      groups = WatchGroups.fromJson(_map(j['watch_groups'])),
      criteria = _strings(j['watch_criteria']),
      attention = _maps(j['attention_students'])
          .map(AttentionStudent.fromJson)
          .toList(),
      tasks = ClassTaskStatus.fromJson(_map(j['task_status'])),
      weekly = WeeklyTrend.fromJson(_map(j['weekly_trend'])),
      lowActivities = _maps(j['low_completion_activities'])
          .map(LowCompletionActivity.fromJson)
          .toList(),
      interventions = _maps(j['suggested_interventions'])
          .map(Intervention.fromJson)
          .toList();
}

class BucketCount {
  final String label;
  final int count;
  const BucketCount(this.label, this.count);
}

class WatchGroups {
  final int onTrack, watch, needsSupport, unknown;
  WatchGroups.fromJson(Map<String, dynamic> j)
    : onTrack = _int(j['on_track']) ?? 0,
      watch = _int(j['watch']) ?? 0,
      needsSupport = _int(j['needs_support']) ?? 0,
      unknown = _int(j['unknown']) ?? 0;
  int get total => onTrack + watch + needsSupport + unknown;
}

class AttentionStudent {
  final int id;
  final String name, risk;
  final String? code, note;
  final double? progress;
  final int? overdue, inactiveDays;
  final List<String> reasons, actions;
  AttentionStudent.fromJson(Map<String, dynamic> j)
    : id = _int(j['userid']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['userid']}',
      code = _string(j['student_code']),
      risk = _string(j['risk_level']) ?? '',
      note = _string(j['note']),
      progress = _double(j['progress']),
      overdue = _int(j['overdue_tasks']),
      inactiveDays = _int(j['days_since_last_activity']),
      reasons = _strings(j['reasons']),
      actions = _strings(j['suggested_actions']);
}

class ClassTaskStatus {
  final int total, completed, pending, overdue;
  ClassTaskStatus.fromJson(Map<String, dynamic> j)
    : total = _int(j['total']) ?? 0,
      completed = _int(j['completed']) ?? 0,
      pending = _int(j['pending']) ?? 0,
      overdue = _int(j['overdue']) ?? 0;
}

class WeekPoint {
  final DateTime weekStart;
  final int activeStudents, events, completed;
  const WeekPoint(this.weekStart, this.activeStudents, this.events, this.completed);
}

class WeeklyTrend {
  final int studentCount;
  final bool engagementAvailable, completionAvailable;
  final List<WeekPoint> points;
  WeeklyTrend.fromJson(Map<String, dynamic> j)
    : studentCount = _int(j['student_count']) ?? 0,
      engagementAvailable = j['engagement_available'] == true,
      completionAvailable = j['completion_available'] == true,
      points = [
        for (final p in _maps(j['points']))
          if (_date(p['week_start']) != null)
            WeekPoint(
              _date(p['week_start'])!,
              _int(p['active_students']) ?? 0,
              _int(p['events']) ?? 0,
              _int(p['completed_activities']) ?? 0,
            ),
      ];
}

class LowCompletionActivity {
  final String title, type;
  final bool duePassed;
  final int studentCount, doneCount;
  final double? rate;
  final String? note, moodlePath;
  final int? courseModuleId;
  final DateTime? due;
  LowCompletionActivity.fromJson(Map<String, dynamic> j)
    : title = _string(j['title']) ?? 'Hoạt động',
      type = _string(j['task_type']) ?? '',
      duePassed = j['due_passed'] == true,
      studentCount = _int(j['student_count']) ?? 0,
      doneCount = _int(j['done_count']) ?? 0,
      rate = _double(j['completion_rate']),
      note = _string(j['note']),
      moodlePath = _string(j['moodle_path']),
      courseModuleId = _int(j['coursemoduleid']),
      due = (_int(j['due_time']) ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(_int(j['due_time'])! * 1000)
          : null;
}

class Intervention {
  final String code, title, reason;
  final DateTime? createdAt;
  Intervention.fromJson(Map<String, dynamic> j)
    : code = _string(j['code']) ?? '',
      title = _string(j['title']) ?? '',
      reason = _string(j['reason']) ?? '',
      createdAt = _date(j['created_at']);
}
