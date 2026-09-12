import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';

class SosState extends Equatable {
  final bool isLoadingContacts;
  final List<Map<String, dynamic>> contacts;
  final bool isBroadcasting;
  final String error;

  const SosState({
    this.isLoadingContacts = false,
    this.contacts = const [],
    this.isBroadcasting = false,
    this.error = '',
  });

  SosState copyWith({
    bool? isLoadingContacts,
    List<Map<String, dynamic>>? contacts,
    bool? isBroadcasting,
    String? error,
  }) {
    return SosState(
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
      contacts: contacts ?? this.contacts,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [isLoadingContacts, contacts, isBroadcasting, error];
}

class SosCubit extends Cubit<SosState> {
  SosCubit() : super(const SosState());

  Future<void> loadContacts() async {
    emit(state.copyWith(isLoadingContacts: true, error: ''));
    try {
      final api = ApiServices.client;
      List<Map<String, dynamic>> contacts = [];
      try {
        final res = await api.get('/api/emergency/contacts');
        if (res['data'] != null) {
          contacts = List<Map<String, dynamic>>.from(res['data']);
        }
      } catch (e) {
        contacts = [
          {'name': 'Police', 'number': '100', 'icon': 'police'},
          {'name': 'Ambulance', 'number': '102', 'icon': 'ambulance'},
          {'name': 'Fire', 'number': '101', 'icon': 'fire'},
          {'name': 'Women Helpline', 'number': '1091', 'icon': 'women'},
        ];
      }
      emit(state.copyWith(isLoadingContacts: false, contacts: contacts));
    } catch (e) {
      emit(state.copyWith(isLoadingContacts: false, error: e.toString()));
    }
  }

  Future<void> broadcastEmergencyBooking(String category, String description, double price) async {
    emit(state.copyWith(isBroadcasting: true, error: ''));
    try {
      final api = ApiServices.client;
      try {
        await api.post('/api/bookings/emergency', data: {
          'category': category,
          'description': description,
          'price': price,
        });
      } catch (e) {
        // mock delay
        await Future.delayed(const Duration(seconds: 3));
      }
      emit(state.copyWith(isBroadcasting: false));
    } catch (e) {
      emit(state.copyWith(isBroadcasting: false, error: e.toString()));
    }
  }
}
