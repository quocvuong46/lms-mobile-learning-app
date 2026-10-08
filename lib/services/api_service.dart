import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/student_dashboard.dart';
import '../models/student_course.dart';
import '../models/student_analytics.dart';
import '../models/teacher_course.dart';
import '../models/teacher_analytics.dart';
import '../models/student_course_detail.dart';
import '../models/teacher_monitoring.dart';
import '../models/learning_notification.dart';

class ApiService {
  Future<List<LearningNotification>> getNotifications({
    bool teacher = false,
  }) => _list(
    '/dev/${teacher ? 'teachers/${ApiConstants.teacherId}' : 'students/${ApiConstants.studentId}'}/notifications',
    LearningNotification.fromJson,
  );
  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _getJson(path);
    final data = response is Map<String, dynamic> ? response['data'] : response;
    if (data is! List) throw const FormatException('Expected list');
    return data.map((v) => parse(v as Map<String, dynamic>)).toList();
  }

  Future<List<StudentTask>> getAllStudentTasks({
    int studentId = ApiConstants.studentId,
  }) => _list('/dev/students/$studentId/tasks', StudentTask.fromJson);
  Future<List<StudentLearningItem>> getContinueLearning({
    int studentId = ApiConstants.studentId,
    int? courseId,
  }) => _list(
    '/dev/students/$studentId/continue-learning${courseId == null ? '' : '?courseId=$courseId'}',
    StudentLearningItem.fromJson,
  );
  Future<List<MonitoredStudent>> getTeacherStudents(
    int courseId, {
    int teacherId = ApiConstants.teacherId,
  }) => _list(
    '/dev/teachers/$teacherId/courses/$courseId/students',
    MonitoredStudent.fromJson,
  );
  Future<MonitoredStudent> getMonitoredStudent(
    int courseId,
    int userId, {
    int teacherId = ApiConstants.teacherId,
  }) async => MonitoredStudent.fromJson(
    await _getJson(
      '/dev/teachers/$teacherId/courses/$courseId/students/$userId',
    ) as Map<String, dynamic>,
  );
  Future<List<MonitoredActivity>> getTeacherActivities(
    int courseId,
    String type, {
    int teacherId = ApiConstants.teacherId,
  }) => _list(
    '/dev/teachers/$teacherId/courses/$courseId/${type == 'assignment' ? 'assignments' : 'quizzes'}',
    MonitoredActivity.fromJson,
  );
  Future<List<ActivityStudent>> getActivityStudents(
    int courseId,
    MonitoredActivity activity, {
    int teacherId = ApiConstants.teacherId,
  }) => _list(
    '/dev/teachers/$teacherId/courses/$courseId/${activity.type == 'assignment' ? 'assignments' : 'quizzes'}/${activity.id}/students',
    ActivityStudent.fromJson,
  );
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Helper method for GET requests with UTF-8 decoding
  void dispose() => _client.close();

  Future<dynamic> _getJson(String path, {bool allowEmpty = false}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final response = await _client
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        if (allowEmpty && decodedBody.trim().isEmpty) return null;
        return jsonDecode(decodedBody);
      } else {
        throw Exception('Lỗi kết nối máy chủ (${response.statusCode})');
      }
    } catch (error, stack) {
      debugPrint('API GET $path: $error\n$stack');
      rethrow;
    }
  }

  // STUDENT APIs
  Future<StudentDashboard> getStudentDashboard({
    int studentId = ApiConstants.studentId,
  }) async {
    final data = await _getJson('/dev/students/$studentId/dashboard');
    if (data is Map<String, dynamic>) {
      // If wrapped in custom API response object e.g. { "data": ... }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StudentDashboard.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StudentDashboard.fromJson(data);
    }
    throw Exception('Dữ liệu bảng điều khiển sinh viên không hợp lệ');
  }

  Future<List<StudentCourse>> getStudentCourses({
    int studentId = ApiConstants.studentId,
  }) async {
    final data = await _getJson('/dev/students/$studentId/courses');
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List;
    } else {
      throw Exception('Dữ liệu danh sách khóa học không hợp lệ');
    }

    return list
        .map((item) => StudentCourse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudentAnalytics> getStudentCourseAnalytics({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) async {
    final url =
        '${ApiConstants.baseUrl}/dev/students/$studentId/courses/$courseId/analytics';
    debugPrint('STUDENT ANALYTICS URL: $url');
    final data = await _getJson(
      '/dev/students/$studentId/courses/$courseId/analytics',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StudentAnalytics.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StudentAnalytics.fromJson(data);
    }
    throw Exception('Dữ liệu phân tích khóa học không hợp lệ');
  }

  // TEACHER APIs
  Future<List<TeacherCourse>> getTeacherCourses({
    int teacherId = ApiConstants.teacherId,
  }) async {
    final data = await _getJson('/dev/teachers/$teacherId/courses');
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List;
    } else {
      throw Exception('Dữ liệu danh sách khóa học giảng viên không hợp lệ');
    }

    return list
        .map((item) => TeacherCourse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherAnalytics> getTeacherCourseAnalytics({
    int teacherId = ApiConstants.teacherId,
    required int courseId,
  }) async {
    final url =
        '${ApiConstants.baseUrl}/dev/teachers/$teacherId/courses/$courseId/analytics';
    debugPrint('TEACHER ANALYTICS URL: $url');
    final data = await _getJson(
      '/dev/teachers/$teacherId/courses/$courseId/analytics',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return TeacherAnalytics.fromJson(data['data'] as Map<String, dynamic>);
      }
      return TeacherAnalytics.fromJson(data);
    }
    throw Exception('Dữ liệu phân tích khóa học giảng viên không hợp lệ');
  }

  Future<List<T>> _studentList<T>(
    int studentId,
    int courseId,
    String endpoint,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _getJson(
      '/dev/students/$studentId/courses/$courseId/$endpoint',
    );
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! List) throw const FormatException('Expected a list');
    return data.map((item) => parse(item as Map<String, dynamic>)).toList();
  }

  Future<List<StudentLearningItem>> getStudentLearningItems({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) => _studentList(
    studentId,
    courseId,
    'learning-items',
    StudentLearningItem.fromJson,
  );

  Future<List<StudentTask>> getStudentTasks({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) => _studentList(studentId, courseId, 'tasks', StudentTask.fromJson);

  Future<List<StudentGrade>> getStudentGrades({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) => _studentList(studentId, courseId, 'grades', StudentGrade.fromJson);

  Future<List<StudentGradeCategory>> getStudentGradeCategories({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) => _studentList(
    studentId,
    courseId,
    'grade-categories',
    StudentGradeCategory.fromJson,
  );

  Future<StudentAttendance?> getStudentAttendance({
    int studentId = ApiConstants.studentId,
    required int courseId,
  }) async {
    final response = await _getJson(
      '/dev/students/$studentId/courses/$courseId/attendance',
      allowEmpty: true,
    );
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected attendance object');
    }
    return StudentAttendance.fromJson(data);
  }
}
