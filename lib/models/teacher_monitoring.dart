import 'student_course_detail.dart';

String? _text(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

class MonitoredStudent {
  final int id;
  final String name;
  final String? studentCode, cohortCode, classCode, majorName;
  String? get code => studentCode;
  String? get academicLabel {
    final parts = [cohortCode, classCode].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  bool get hasAcademicProfile =>
      [studentCode, cohortCode, classCode, majorName].any((v) => v != null);
  final String? email;
  final double? progress, attendance, averageGrade;
  final int? pending, overdue, inactiveDays;
  final String? risk;
  final bool? needsAttention;
  final List<StudentTask> tasks;
  MonitoredStudent.fromJson(Map<String, dynamic> j)
    : id = (j['userid'] as num).toInt(),
      name = j['fullname'] as String? ?? 'Sinh viên #${j['userid']}',
      studentCode = _text(j['student_code']) ?? _text(j['idnumber']),
      cohortCode = _text(j['cohort_code']),
      classCode = _text(j['class_code']),
      majorName = _text(j['major_name']),
      email = _text(j['email']),
      progress = (j['progress'] as num?)?.toDouble(),
      attendance = (j['attendance'] as num?)?.toDouble(),
      averageGrade = (j['average_grade'] as num?)?.toDouble(),
      pending = (j['pending_tasks'] as num?)?.toInt(),
      overdue = (j['overdue_tasks'] as num?)?.toInt(),
      inactiveDays = (j['days_since_last_activity'] as num?)?.toInt(),
      risk = j['risk_level'] as String?,
      needsAttention = j['needs_attention'] as bool?,
      tasks = (j['tasks'] as List? ?? [])
          .map((v) => StudentTask.fromJson(v as Map<String, dynamic>))
          .toList();
  // Matches the confirmed teacher_course_overview definition: HIGH or MEDIUM.
  bool get needsSupport =>
      needsAttention ?? (risk == 'HIGH' || risk == 'MEDIUM');

  /// Observable risk V1 signals supplied by the monitoring API.
  /// Never recomputes backend risk_level; absent fields produce no reason.
  /// Engagement is not currently returned per student by this endpoint.
  List<String> get riskReasons => [
    if (overdue != null && overdue! > 0) '$overdue bài đã quá hạn',
    if (inactiveDays != null && inactiveDays! >= 7)
      '$inactiveDays ngày chưa hoạt động',
    if (progress != null && progress! < 30)
      'Tiến độ học tập dưới 30%'
    else if (progress != null && progress! < 60)
      'Tiến độ học tập còn thấp',
  ];

  /// Explains membership without inventing a cause for the API's risk level.
  String? get supportBasisLabel => !needsSupport
      ? null
      : risk?.toUpperCase() == 'HIGH'
      ? 'Cần theo dõi theo mức nguy cơ cao trong dữ liệu khóa học.'
      : risk?.toUpperCase() == 'MEDIUM'
      ? 'Cần theo dõi theo mức nguy cơ trung bình trong dữ liệu khóa học.'
      : 'Được đánh dấu cần theo dõi trong dữ liệu khóa học.';

  String get riskExplanationFallback =>
      risk?.toUpperCase() == 'LOW' &&
          progress != null &&
          overdue != null &&
          inactiveDays != null
      ? 'Chưa phát hiện dấu hiệu cần ưu tiên theo dõi.'
      : 'Chưa đủ dữ liệu để giải thích mức nguy cơ hiện tại.';

  String get activityLabel => inactiveDays == null
      ? 'Chưa có dữ liệu hoạt động'
      : inactiveDays == 0
      ? 'Hoạt động gần nhất: hôm nay'
      : 'Hoạt động gần nhất: $inactiveDays ngày trước';
  String get riskLabel => switch (risk?.toUpperCase()) {
    'HIGH' => 'Nguy cơ cao',
    'MEDIUM' => 'Nguy cơ trung bình',
    'LOW' => 'Nguy cơ thấp',
    _ => 'Chưa có mức nguy cơ',
  };
  String? get identityLabel => code != null ? 'MSSV: $code' : email;
}

class MonitoredActivity {
  final int id;
  final int? courseModuleId;
  final String title, type;
  final String? moodlePath;
  final DateTime? deadline;
  final int? total,
      done,
      notDone,
      unknown,
      needsGrading,
      notAttempted,
      inProgress;
  final double? average;
  MonitoredActivity.fromJson(Map<String, dynamic> j)
    : id = (j['source_id'] as num).toInt(),
      courseModuleId = (j['coursemoduleid'] as num?)?.toInt(),
      title = j['title'] as String? ?? 'Hoạt động',
      type = j['task_type'] as String,
      moodlePath = j['moodle_path'] as String?,
      deadline = unixSeconds((j['due_time'] as num?)?.toInt()),
      total = (j['student_count'] as num?)?.toInt(),
      done = (j['done_count'] as num?)?.toInt(),
      notAttempted = (j['not_attempted_count'] as num?)?.toInt(),
      inProgress = (j['inprogress_count'] as num?)?.toInt(),
      notDone = (j['not_done_count'] as num?)?.toInt(),
      unknown = (j['unknown_count'] as num?)?.toInt(),
      needsGrading = (j['needs_grading_count'] as num?)?.toInt(),
      average = (j['average_grade_percentage'] as num?)?.toDouble();
}

class ActivityStudent {
  final MonitoredStudent student;
  final bool? done;
  final String? sourceStatus, quizState;
  final double? grade, gradePercentage;
  ActivityStudent.fromJson(Map<String, dynamic> j)
    : student = MonitoredStudent.fromJson(j),
      done = j['done'] as bool?,
      sourceStatus = j['source_status'] as String?,
      quizState = j['quiz_state'] as String?,
      grade = (j['finalgrade'] as num?)?.toDouble(),
      gradePercentage = (j['grade_percentage'] as num?)?.toDouble();
  String get status => switch (sourceStatus ?? quizState) {
    'submitted' => 'Đã nộp',
    'draft' => 'Bản nháp',
    'new' => 'Chưa nộp',
    'finished' => 'Đã làm',
    'inprogress' => 'Đang làm',
    'overdue' => 'Quá hạn',
    'abandoned' => 'Chưa hoàn tất',
    _ => done == false ? 'Chưa hoàn thành' : 'Chưa có trạng thái',
  };
  String groupLabel(String activityType) {
    if (activityType == 'assignment') {
      if (sourceStatus == 'submitted' || done == true) return 'Đã nộp';
      return done == false ? 'Chưa nộp' : 'Chưa có trạng thái';
    }
    final state = quizState ?? sourceStatus;
    if (state == 'finished' || done == true) return 'Đã hoàn tất';
    if (state == 'inprogress') return 'Đang làm';
    if (state == null && done == false) return 'Chưa bắt đầu';
    // An abandoned/overdue attempt is not the same as never starting a quiz.
    return state == 'overdue' || state == 'abandoned'
        ? 'Chưa hoàn tất'
        : 'Chưa có trạng thái';
  }
}
