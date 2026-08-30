part of 'support_cubit.dart';

enum SupportStatus { initial, loading, loaded, submitting, ticketSubmitted, failure }

class SupportState extends Equatable {
  const SupportState({
    this.status = SupportStatus.initial,
    this.messages = const [],
    this.lastTicketSubject,
  });

  final SupportStatus status;
  final List<SupportMessage> messages;
  final String? lastTicketSubject;

  SupportState copyWith({
    SupportStatus? status,
    List<SupportMessage>? messages,
    String? lastTicketSubject,
  }) {
    return SupportState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      lastTicketSubject: lastTicketSubject ?? this.lastTicketSubject,
    );
  }

  @override
  List<Object?> get props => [status, messages, lastTicketSubject];
}
