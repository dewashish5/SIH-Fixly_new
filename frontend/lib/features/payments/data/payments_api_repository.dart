import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';

class PaymentConfig {
  const PaymentConfig({
    required this.keyId,
    required this.currency,
  });

  final String keyId;
  final String currency;
}

class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  final String orderId;
  final double amountPaise;
  final String currency;
  final String keyId;

  double get amountRupees => amountPaise / 100;
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

  Future<PaymentConfig> fetchConfig() async {
    final res = await _api.get(ApiEndpoints.paymentConfig);
    if (res['success'] != true || res['keyId'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Payment config failed');
    }
    return PaymentConfig(
      keyId: res['keyId'].toString(),
      currency: (res['currency'] as String?) ?? 'INR',
    );
  }

  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amountRupees,
  }) async {
    final res = await _api.post(ApiEndpoints.createPaymentOrder, data: {
      'bookingId': bookingId,
      'amount': amountRupees,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Create order failed');
    }
    final amountPaise = (res['amount'] as num?)?.toDouble() ??
        (amountRupees * 100).roundToDouble();
    return PaymentOrder(
      orderId: (res['orderId'] ?? '').toString(),
      amountPaise: amountPaise,
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
    final res = await _api.post(ApiEndpoints.verifyPayment, data: {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'bookingId': bookingId,
    });
    return res['success'] == true;
  }

  Future<WalletSnapshot> workerWallet() async {
    final res = await _api.get(ApiEndpoints.workerWallet);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Wallet failed');
    }
    final data = res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : res;
    final history = data['transactions'] ?? res['transactions'];
    return WalletSnapshot(
      balance: (data['availableBalance'] as num?)?.toDouble() ??
          (res['walletBalance'] as num?)?.toDouble() ??
          0,
      history: history is List
          ? history
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
          : const [],
    );
  }

  Future<Map<String, dynamic>> workerEarningsSummary() async {
    final res = await _api.get(ApiEndpoints.workerEarningsSummary);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Earnings failed');
    }
    return Map<String, dynamic>.from(res['data'] as Map? ?? res);
  }

  Future<void> withdraw(double amount) async {
    final res = await _api.post(ApiEndpoints.workerWithdraw, data: {
      'amount': amount,
    });
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Withdraw failed');
    }
  }

  Future<WalletSnapshot> walletHistory() async {
    final res = await _api.get(ApiEndpoints.paymentWalletHistory);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Wallet failed');
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
  }
}
