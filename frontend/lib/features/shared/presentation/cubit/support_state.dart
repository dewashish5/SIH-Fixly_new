part of 'support_cubit.dart';

enum SupportStatus { initial, loading, loaded, submitting, ticketSubmitted, failure }

class SupportState extends Equatable {
  const SupportState({
    this.status = SupportStatus.initial,
    this.ticketId,
    this.ticketNumber,
    this.ticketStatus = 'BOT_ACTIVE',
    this.handledBy = 'BOT',
    this.messages = const [],
    this.quickReplies = const [],
    this.isSending = false,
    this.isEscalating = false,
    this.errorMessage,
    this.lastTicketSubject,
  });

  final SupportStatus status;
  final String? ticketId;
  final String? ticketNumber;
  final String ticketStatus; // 'BOT_ACTIVE', 'ESCALATED', 'AGENT_ACTIVE', 'RESOLVED', 'CLOSED'
  final String handledBy; // 'BOT', 'HUMAN'
  final List<SupportMessageModel> messages;
  final List<String> quickReplies;
  final bool isSending;
  final bool isEscalating;
  final String? errorMessage;
  final String? lastTicketSubject;

  bool get isHandledByBot => handledBy == 'BOT';
  bool get isEscalated => ticketStatus == 'ESCALATED';
  bool get isAgentActive => ticketStatus == 'AGENT_ACTIVE';
  bool get isResolved => ticketStatus == 'RESOLVED' || ticketStatus == 'CLOSED';

  SupportState copyWith({
    SupportStatus? status,
    String? ticketId,
    String? ticketNumber,
    String? ticketStatus,
    String? handledBy,
    List<SupportMessageModel>? messages,
    List<String>? quickReplies,
    bool? isSending,
    bool? isEscalating,
    String? errorMessage,
    String? lastTicketSubject,
  }) {
    return SupportState(
      status: status ?? this.status,
      ticketId: ticketId ?? this.ticketId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      handledBy: handledBy ?? this.handledBy,
      messages: messages ?? this.messages,
      quickReplies: quickReplies ?? this.quickReplies,
      isSending: isSending ?? this.isSending,
      isEscalating: isEscalating ?? this.isEscalating,
      errorMessage: errorMessage ?? this.errorMessage,
      lastTicketSubject: lastTicketSubject ?? this.lastTicketSubject,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ticketId,
        ticketNumber,
        ticketStatus,
        handledBy,
        messages,
        quickReplies,
        isSending,
        isEscalating,
        errorMessage,
        lastTicketSubject,
      ];
}
