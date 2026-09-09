import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';

class WelfareState extends Equatable {
  final bool isLoading;
  final double balance;
  final bool hasUan;
  final List<Map<String, dynamic>> resources;
  final String error;

  const WelfareState({
    this.isLoading = false,
    this.balance = 0.0,
    this.hasUan = false,
    this.resources = const [],
    this.error = '',
  });

  WelfareState copyWith({
    bool? isLoading,
    double? balance,
    bool? hasUan,
    List<Map<String, dynamic>>? resources,
    String? error,
  }) {
    return WelfareState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      hasUan: hasUan ?? this.hasUan,
      resources: resources ?? this.resources,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [isLoading, balance, hasUan, resources, error];
}

class WelfareCubit extends Cubit<WelfareState> {
  WelfareCubit() : super(const WelfareState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: ''));
    try {
      final api = ApiServices.client;
      
      double balance = 5000.0;
      bool hasUan = false;
      List<Map<String, dynamic>> resources = [];
      
      try {
        final res = await api.get('/api/welfare');
        balance = (res['balance'] as num?)?.toDouble() ?? balance;
        hasUan = (res['hasUan'] as bool?) ?? hasUan;
      } catch (e) {
        hasUan = true; // mock
      }

      try {
        final res2 = await api.get('/api/welfare/resources');
        if (res2['data'] != null) {
          resources = List<Map<String, dynamic>>.from(res2['data']);
        }
      } catch (e) {
        resources = [
          {
            'title': 'Safety Guidelines',
            'description': 'Read the latest safety protocols for workers.',
            'url': 'https://example.com/safety'
          },
          {
            'title': 'Health Insurance Details',
            'description': 'Understand your coverage and benefits.',
            'url': 'https://example.com/insurance'
          }
        ];
      }

      emit(state.copyWith(
        isLoading: false,
        balance: balance,
        hasUan: hasUan,
        resources: resources,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
