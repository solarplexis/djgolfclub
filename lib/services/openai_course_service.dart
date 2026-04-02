import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';

class OpenAiCourseService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static String _buildPrompt(String courseName) => '''
You are a golf course data assistant.
Return ONLY a valid JSON object — no explanation, no markdown, no code fences.

The JSON must follow this exact schema:
{
  "name": "<official full course name>",
  "holes": [
    { "number": 1, "par": 4 },
    ...
  ]
}

Rules:
- Include ALL holes the course has. Most regulation courses have 18 holes — return all 18 unless the course is specifically a 9-hole course.
- Number holes sequentially starting at 1.
- Each "par" must be 3, 4, or 5.
- Use the real par values for the course if known; otherwise include but leave blank (null) for any holes you don't know.
- Do not truncate or stop early — the holes array must contain every hole.
- Do not include yardage, handicap index, or any other fields.
- All courses either have 9 or 18 holes. Your answers MUST reflect this reality.
- DO NOT MAKE SHIT UP.

Course: $courseName
''';

  /// Looks up a golf course by name and returns a [Course] with par per hole.
  /// Throws a [CourseAiException] on failure.
  static Future<Course> fetchCourse(String courseName) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw CourseAiException('OPENAI_API_KEY is not set in .env');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'temperature': 0,
        'messages': [
          {'role': 'user', 'content': _buildPrompt(courseName)},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw CourseAiException(
          'OpenAI request failed (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    print('OpenAI response: $body');
    final content =
        (body['choices'] as List).first['message']['content'] as String;

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(content.trim()) as Map<String, dynamic>;
    } catch (_) {
      throw CourseAiException('Could not parse AI response as JSON: $content');
    }

    final name = data['name'] as String? ?? courseName;
    final rawHoles = data['holes'] as List?;
    if (rawHoles == null || rawHoles.isEmpty) {
      throw CourseAiException('AI returned no holes for "$courseName"');
    }

    final holes = rawHoles.map((h) {
      final map = Map<String, dynamic>.from(h as Map);
      return Hole(number: map['number'] as int, par: map['par'] as int);
    }).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Course(name: name, holes: holes);
  }
}

class CourseAiException implements Exception {
  final String message;
  const CourseAiException(this.message);

  @override
  String toString() => message;
}
