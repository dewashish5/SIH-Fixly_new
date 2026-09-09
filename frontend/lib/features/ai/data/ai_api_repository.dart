import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';

class AiAnalysis {
  const AiAnalysis({
    required this.category,
    required this.estimatedHours,
    required this.aiNote,
    this.suggestedService,
    this.issueImageUrl,
  });

  final String category;
  final double estimatedHours;
  final String aiNote;
  final String? suggestedService;
  final String? issueImageUrl;
}

class AiAgentResponse {
  const AiAgentResponse({
    required this.reply,
    this.state = const {},
    this.action,
    this.booking,
    this.bookings = const [],
    this.suggestedReplies = const [],
  });

  final String reply;
  final Map<String, dynamic> state;
  final String? action;
  final Map<String, dynamic>? booking;
  final List<dynamic> bookings;
  final List<String> suggestedReplies;
}

class AiApiRepository {
  AiApiRepository({ApiClient? client}) : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<AiAgentResponse> chatWithAgent({
    required String message,
    Map<String, dynamic>? conversationState,
    String? language,
    List<double>? coordinates,
    String? addressLine,
  }) async {
    final res = await _api.post(
      ApiEndpoints.aiAgentChat,
      data: {
        'message': message,
        'conversationState': conversationState ?? {},
        'language': language ?? 'en',
        'coordinates': ?coordinates,
        'addressLine': ?addressLine,
      },
    );

    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'AI agent failed');
    }

    final rawSuggestions = res['suggestedReplies'];
    final suggestions = rawSuggestions is List
        ? rawSuggestions.map((e) => e.toString()).toList()
        : <String>[];

    return AiAgentResponse(
      reply: res['reply']?.toString() ?? '',
      state: (res['state'] as Map<String, dynamic>?) ?? {},
      action: res['action']?.toString(),
      booking: res['booking'] as Map<String, dynamic>?,
      bookings: res['bookings'] as List<dynamic>? ?? const [],
      suggestedReplies: suggestions,
    );
  }

  Future<AiAnalysis> analyzeIssue(
    String problemDescription, {
    String? imagePath,
  }) async {
    final Object data;
    if (imagePath == null || imagePath.isEmpty) {
      data = {'problemDescription': problemDescription};
    } else {
      data = FormData.fromMap({
        'problemDescription': problemDescription,
        'issueImage': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split(RegExp(r'[/\\]')).last,
        ),
      });
    }

    final res = await _api.post(ApiEndpoints.aiAnalyzeIssue, data: data);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'AI failed');
    }
    final a = res['analysis'] as Map<String, dynamic>? ?? {};
    return AiAnalysis(
      category: (a['category'] as String?) ?? 'General',
      estimatedHours: (a['estimatedHours'] as num?)?.toDouble() ?? 1,
      aiNote: (a['aiNote'] as String?) ?? '',
      suggestedService: a['suggestedService']?.toString(),
      issueImageUrl: a['issueImageUrl'] as String?,
    );
  }
}
