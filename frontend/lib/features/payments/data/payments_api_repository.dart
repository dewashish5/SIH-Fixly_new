import '../../../core/network/api_client.dart';
import '../../../core/network/api_enpoints.dart';
import '../../../core/network/api_exception.dart';

class PaymentConfig {
  const PaymentConfig({
    required this.keyId,
    required this.currency,
    this.mode = 'test',
  });

  final String keyId;
  final String currency;
  final String mode;

  bool get isTestMode =>
      mode != 'live' && (mode == 'test' || keyId.startsWith('rzp_test'));
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
    this.totalEarnings = 0,
    this.pendingBalance = 0,
    this.payoutMethod,
    this.upiId,
    this.accountHolderName,
    this.bankAccount,
    this.ifscCode,
    this.bankName,
  });

  final double balance;
  final double totalEarnings;
  final double pendingBalance;
  final List<Map<String, dynamic>> history;
  final String? payoutMethod;
  final String? upiId;
  final String? accountHolderName;
  final String? bankAccount;
  final String? ifscCode;
  final String? bankName;

  bool get hasPayoutAccount =>
      (upiId != null && upiId!.isNotEmpty) ||
      (bankAccount != null && bankAccount!.isNotEmpty);
}

class PaymentsApiRepository {
  PaymentsApiRepository({ApiClient? client})
      : _api = client ?? ApiServices.client;

  final ApiClient _api;

  List<Map<String, dynamic>> _mapHistory(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      final paymentId = (map['paymentId'] ?? map['transactionId'] ?? '')
          .toString();
      map['transactionId'] = paymentId.isNotEmpty
          ? paymentId
          : (map['orderId'] ?? map['_id'] ?? '').toString();
      map['description'] = (map['description'] ?? '').toString();
      map['type'] = (map['type'] ?? 'CREDIT').toString();
      return map;
    }).toList();
  }

  Future<PaymentConfig> fetchConfig() async {
    final res = await _api.get(ApiEndpoints.paymentConfig);
    if (res['success'] != true || res['keyId'] == null) {
      throw ApiException(res['message']?.toString() ?? 'Payment config failed');
    }
    return PaymentConfig(
      keyId: res['keyId'].toString(),
      currency: (res['currency'] as String?) ?? 'INR',
      mode: (res['mode'] as String?) ?? 'test',
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
    final history = data['walletTransactions'] ??
        data['transactions'] ??
        res['walletTransactions'] ??
        res['transactions'];
    final upi = data['upi'] is Map ? Map<String, dynamic>.from(data['upi'] as Map) : null;
    final bank = data['bank'] is Map ? Map<String, dynamic>.from(data['bank'] as Map) : null;

    return WalletSnapshot(
      balance: (data['availableBalance'] as num?)?.toDouble() ??
          (res['walletBalance'] as num?)?.toDouble() ??
          0,
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ??
          (data['totalEarned'] as num?)?.toDouble() ??
          0,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0,
      history: _mapHistory(history),
      payoutMethod: data['payoutMethod']?.toString(),
      upiId: upi?['upiId']?.toString(),
      accountHolderName: bank?['accountHolderName']?.toString(),
      bankAccount: bank?['accountNumber']?.toString(),
      ifscCode: bank?['ifscCode']?.toString(),
      bankName: bank?['bankName']?.toString(),
    );
  }

  Future<void> updatePayoutDetails({
    required String payoutMethod,
    String? upiId,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
  }) async {
    final body = <String, dynamic>{
      'payoutMethod': payoutMethod,
    };
    if (upiId != null) {
      body['upi'] = {'upiId': upiId.trim()};
      body['upiId'] = upiId.trim();
    }
    if (accountNumber != null || accountHolderName != null || ifscCode != null) {
      body['bank'] = {
        'accountHolderName': accountHolderName?.trim() ?? '',
        'accountNumber': accountNumber?.trim() ?? '',
        'ifscCode': ifscCode?.trim() ?? '',
        if (bankName != null && bankName.trim().isNotEmpty) 'bankName': bankName.trim(),
      };
    }
    final res = await _api.put(ApiEndpoints.setupProfile, data: body);
    if (res['success'] != true) {
      throw ApiException(res['message']?.toString() ?? 'Failed to update payout details');
    }
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
    final history = res['history'] ??
        res['walletTransactions'] ??
        res['transactions'] ??
        (res['data'] is Map
            ? (res['data'] as Map)['walletTransactions'] ??
                (res['data'] as Map)['transactions']
            : null);
    return WalletSnapshot(
      balance: (res['walletBalance'] as num?)?.toDouble() ?? 0,
      totalEarnings: (res['totalSpent'] as num?)?.toDouble() ?? 0,
      history: _mapHistory(history),
    );
  }
}
