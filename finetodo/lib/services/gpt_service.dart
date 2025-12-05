import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../data/models/api_status.dart';

class GptService {
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static final DateTime _apiExpiryDate = DateTime(2025, 12, 25);

  final String apiToken;
  final Logger _logger = Logger();

  GptService({required this.apiToken});

  /// Check if API is still valid
  bool isApiValid() {
    return DateTime.now().isBefore(_apiExpiryDate);
  }

  /// Get days remaining before API expires
  int daysRemaining() {
    final now = DateTime.now();
    if (now.isAfter(_apiExpiryDate)) return 0;
    return _apiExpiryDate.difference(now).inDays;
  }

  /// Generate AI summary of task progress
  Future<ApiResponse> generateSummary(String tasksSummary) async {
    try {
      if (!isApiValid()) {
        return ApiResponse(
          status: ApiStatus.expired,
          message:
              'API token expired on December 25, 2025. Please update your API token.',
          expiryDate: _apiExpiryDate,
        );
      }

      final response = await http
          .post(
            Uri.parse(_apiEndpoint),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gpt-4-turbo',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a productivity assistant. Provide encouraging summaries of task completion.',
                },
                {
                  'role': 'user',
                  'content':
                      'Here is my task summary: $tasksSummary. Please provide an encouraging summary and next steps.',
                },
              ],
              'temperature': 0.7,
              'max_tokens': 200,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['choices'][0]['message']['content'];

        _logger.i('[GPT] Summary generated successfully');

        return ApiResponse(
          status: ApiStatus.success,
          data: summary,
          expiryDate: _apiExpiryDate,
        );
      } else if (response.statusCode == 401) {
        _logger.e('[GPT] Authentication failed: ${response.body}');
        return ApiResponse(
          status: ApiStatus.validationError,
          message: 'Invalid API token. Please check your credentials.',
        );
      } else {
        _logger.e('[GPT] API Error: ${response.statusCode}');
        return ApiResponse(
          status: ApiStatus.failure,
          message: 'Failed to generate summary. Try again later.',
        );
      }
    } on Exception catch (e) {
      _logger.e('[GPT] Exception: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        return ApiResponse(
          status: ApiStatus.networkError,
          message: 'Network error. Check your connection.',
        );
      }

      return ApiResponse(status: ApiStatus.failure, message: e.toString());
    }
  }

  /// Generate motivational message
  Future<ApiResponse> generateMotivation(int tasksCompleted) async {
    try {
      if (!isApiValid()) {
        return ApiResponse(
          status: ApiStatus.expired,
          message: 'API token expired. Please update it.',
          expiryDate: _apiExpiryDate,
        );
      }

      final response = await http
          .post(
            Uri.parse(_apiEndpoint),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gpt-4-turbo',
              'messages': [
                {
                  'role': 'user',
                  'content':
                      'Generate a short, motivational message for someone who has completed $tasksCompleted tasks today. Keep it to one sentence.',
                },
              ],
              'temperature': 0.8,
              'max_tokens': 100,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final motivation = data['choices'][0]['message']['content'];

        return ApiResponse(
          status: ApiStatus.success,
          data: motivation,
          expiryDate: _apiExpiryDate,
        );
      }

      return ApiResponse(
        status: ApiStatus.failure,
        message: 'Could not generate motivation',
      );
    } catch (e) {
      return ApiResponse(
        status: ApiStatus.networkError,
        message: 'Network error occurred',
      );
    }
  }
}
