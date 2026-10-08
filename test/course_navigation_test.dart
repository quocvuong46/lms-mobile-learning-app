import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/teacher_course.dart';
import 'package:lms_mobile_app/screens/student/student_courses_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_courses_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';

void main() {
  testWidgets('Student course opens course detail, not analytics', (
    tester,
  ) async {
    final requests = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request.url.path);
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/courses')
                ? [
                    {
                      'courseid': 10,
                      'course_name': 'Android',
                      'course_shortname': 'AND',
                    },
                  ]
                : [],
          ),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: StudentCoursesScreen(apiService: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCourseDetailScreen), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(5));
    expect(requests.any((path) => path.endsWith('/analytics')), isFalse);
  });

  testWidgets('Teacher navigation loads monitoring tabs and analytics last', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request.url.path);
        final data = request.url.path.endsWith('/courses')
            ? [
                {
                  'courseid': 10,
                  'course_name': 'Android',
                  'student_count': 4,
                  'students_need_attention': 1,
                  'high_risk_students': 0,
                  'average_progress': 35,
                },
              ]
            : request.url.path.endsWith('/analytics')
            ? {
                'courseid': 10,
                'medium_risk_students': 2,
                'high_risk_students': 0,
                'low_risk_students': 2,
              }
            : [];
        return http.Response(jsonEncode(data), 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: TeacherCoursesScreen(apiService: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android'));
    await tester.pumpAndSettle();
    expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
    expect(find.text('1 sinh viên cần theo dõi'), findsOneWidget);
    expect(find.text('0 sinh viên nguy cơ cao'), findsOneWidget);
    for (final (tab, message) in [
      ('Sinh viên', 'Không có sinh viên phù hợp'),
      ('Bài tập', 'Khóa học chưa có bài tập'),
      ('Bài kiểm tra', 'Khóa học chưa có bài kiểm tra'),
      ('Phân tích', 'Sinh viên cần hỗ trợ'),
    ]) {
      final target = find.widgetWithText(Tab, tab);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Sinh viên nguy cơ trung bình: 2'), findsOneWidget);
    expect(
      requests.every(
        (path) => [
          'courses',
          'students',
          'assignments',
          'quizzes',
          'analytics',
        ].contains(path.split('/').last),
      ),
      isTrue,
    );
  });

  testWidgets('Missing Teacher metrics are not converted into zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TeacherCourseSummary(
              course: TeacherCourse(courseId: 10, courseName: 'Demo'),
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('Sinh viên cần theo dõi: Chưa có dữ liệu'),
      findsOneWidget,
    );
    expect(find.text('0 sinh viên cần theo dõi'), findsNothing);
  });
}
