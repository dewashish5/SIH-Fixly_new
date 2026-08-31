import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final String orderId;
  final double amount;
  final String currency;
  final String keyId;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.history,
  });

  final double balance;
  final List<Map<String, dynamic>> history;
}

class PaymentsApiRepository {
  PaymentsApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amount,
  }) async {
    final res = await _api.post('/api/payments/create-order', data: {
      'bookingId': bookingId,
      'amount': amount,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Create order failed');
    }
    return PaymentOrder(
      orderId: (res['orderId'] ?? '').toString(),
      amount: (res['amount'] as num?)?.toDouble() ?? amount,
      currency: (res['currency'] as String?) ?? 'INR',
      keyId: (res['keyId'] ?? '').toString(),
    );
  }

  Future<bool> verify({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String bookingId,
  }) async {
    final res = await _api.post('/api/payments/verify', data: {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'bookingId': bookingId,
    });
    return res['success'] == true;
  }

  Future<WalletSnapshot> walletHistory() async {
    try {
      final res = await _api.get('/api/payments/wallet-history');
      if (res['success'] != true) {
        return const WalletSnapshot(balance: 0, history: []);
      }
      final history = res['history'];
      return WalletSnapshot(
        balance: (res['walletBalance'] as num?)?.toDouble() ?? 0,
        history: history is List
            ? history
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [],
      );
    } catch (_) {
      return const WalletSnapshot(balance: 0, history: []);
    }
  }
}
