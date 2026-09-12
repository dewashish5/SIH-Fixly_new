import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';

class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.role,
    required this.body,
    required this.createdAt,
    this.senderName,
    this.attachments = const [],
    this.mediaType,
    this.quickReplies = const [],
  });

  final String id;
  final String role; // 'customer', 'worker', 'ai', 'admin', 'system'
  final String body;
  final DateTime createdAt;
  final String? senderName;
  final List<String> attachments;
  final String? mediaType; // 'image', 'video', 'audio', null
  final List<String> quickReplies;

  bool get isUser => role == 'customer' || role == 'worker';
  bool get isAi => role == 'ai';
  bool get isAdmin => role == 'admin';
  bool get isSystem => role == 'system';
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isImage => mediaType == 'image' || (hasAttachments && attachments.first.contains(RegExp(r'\.(jpg|jpeg|png|webp|gif)', caseSensitive: false)));
  bool get isVideo => mediaType == 'video' || (hasAttachments && attachments.first.contains(RegExp(r'\.(mp4|mov|avi|mkv)', caseSensitive: false)));
  bool get isAudio => mediaType == 'audio' || (hasAttachments && attachments.first.contains(RegExp(r'\.(m4a|mp3|wav|aac|ogg)', caseSensitive: false)));

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    final rawAtt = json['attachments'];
    final attList = <String>[];
    if (rawAtt is List) {
      for (final a in rawAtt) {
        if (a != null) attList.add(a.toString());
      }
    }

    final rawSnippets = json['quickReplies'];
    final snippets = <String>[];
    if (rawSnippets is List) {
      for (final s in rawSnippets) {
        if (s != null) snippets.add(s.toString());
      }
    }

    return SupportMessageModel(
      id: json['_id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      role: json['role']?.toString() ?? 'customer',
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      senderName: json['senderName']?.toString(),
      attachments: attList,
      mediaType: json['mediaType']?.toString(),
      quickReplies: snippets,
    );
  }
}

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.handledBy,
    required this.messages,
    this.quickReplies = const [],
  });

  final String id;
  final String ticketNumber;
  final String status; // 'BOT_ACTIVE', 'ESCALATED', 'AGENT_ACTIVE', 'RESOLVED', 'CLOSED'
  final String handledBy; // 'BOT', 'HUMAN'
  final List<SupportMessageModel> messages;
  final List<String> quickReplies;

  bool get isHandledByBot => handledBy == 'BOT';
  bool get isEscalated => status == 'ESCALATED';
  bool get isAgentActive => status == 'AGENT_ACTIVE';
  bool get isResolved => status == 'RESOLVED' || status == 'CLOSED';

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final rawMsgs = json['messages'];
    final msgs = <SupportMessageModel>[];
    if (rawMsgs is List) {
      for (final m in rawMsgs) {
        if (m is Map<String, dynamic>) {
          msgs.add(SupportMessageModel.fromJson(m));
        }
      }
    }

    final rawSnippets = json['quickReplies'];
    final snippets = <String>[];
    if (rawSnippets is List) {
      for (final s in rawSnippets) {
        if (s != null) snippets.add(s.toString());
      }
    }

    return SupportTicketModel(
      id: json['_id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'BOT_ACTIVE',
      handledBy: json['handledBy']?.toString() ?? 'BOT',
      messages: msgs,
      quickReplies: snippets,
    );
  }
}

class SupportApiRepository {
  SupportApiRepository({ApiClient? client}) : _api = client ?? ApiServices.client;

  final ApiClient _api;

  /// Fetch or initialize active support ticket
  Future<SupportTicketModel?> getActiveTicket() async {
    try {
      final res = await _api.get(
        ApiEndpoints.supportActiveTicket,
        forceNetwork: true,
      );
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return SupportTicketModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Send message in support chat (with optional media attachments)
  Future<SupportTicketModel?> sendMessage(
    String text, {
    String? ticketId,
    List<String>? attachments,
    String? mediaType,
  }) async {
    try {
      final payload = <String, dynamic>{'message': text};
      if (ticketId != null) payload['ticketId'] = ticketId;
      if (attachments != null && attachments.isNotEmpty) {
        payload['attachments'] = attachments;
      }
      if (mediaType != null) payload['mediaType'] = mediaType;

      final res = await _api.post(
        ApiEndpoints.supportSendMessage,
        data: payload,
      );
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return SupportTicketModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Escalate conversation to human support agent
  Future<SupportTicketModel?> escalateTicket({String? ticketId}) async {
    try {
      final payload = <String, dynamic>{};
      if (ticketId != null) payload['ticketId'] = ticketId;
      final res = await _api.post(
        ApiEndpoints.supportEscalate,
        data: payload,
      );
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return SupportTicketModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reset / Start a fresh support chat with AI
  Future<SupportTicketModel?> resetTicket() async {
    try {
      final res = await _api.post(ApiEndpoints.supportReset);
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return SupportTicketModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
