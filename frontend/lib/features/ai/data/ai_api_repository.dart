import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AiAnalysis {
  const AiAnalysis({
    required this.category,
    required this.estimatedHours,
    required this.aiNote,
    this.suggestedService,
  });

  final String category;
  final double estimatedHours;
  final String aiNote;
  final String? suggestedService;
}

class AiApiRepository {
  AiApiRepository({ApiClient? client}) : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<AiAnalysis> analyzeIssue(String problemDescription) async {
    final res = await _api.post('/api/ai/analyze-issue', data: {
      'problemDescription': problemDescription,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'AI failed');
    }
    final a = res['analysis'] as Map<String, dynamic>? ?? {};
    return AiAnalysis(
      category: (a['category'] as String?) ?? 'General',
      estimatedHours: (a['estimatedHours'] as num?)?.toDouble() ?? 1,
      aiNote: (a['aiNote'] as String?) ?? '',
      suggestedService: a['suggestedService']?.toString(),
    );
  }
}
