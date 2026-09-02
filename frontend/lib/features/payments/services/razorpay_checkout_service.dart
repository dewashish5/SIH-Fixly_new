import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../data/payments_api_repository.dart';

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

class RazorpayCheckoutService {
  Razorpay? _razorpay;

  Future<RazorpayCheckoutResult> openCheckout({
    required PaymentOrder order,
    required String description,
    String? customerName,
    String? email,
    String? phone,
  }) async {
    _razorpay?.clear();
    _razorpay = Razorpay();
    final completer = Completer<RazorpayCheckoutResult>();

    void completeError(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
      _razorpay?.clear();
    }

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (orderId == null || paymentId == null || signature == null) {
        completeError(Exception('Incomplete Razorpay success payload'));
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayCheckoutResult(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          ),
        );
      }
      _razorpay?.clear();
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      final message = response.message ?? 'Payment cancelled';
      completeError(Exception(message));
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    final options = <String, dynamic>{
      'key': order.keyId,
      'amount': order.amountPaise.round(),
      'currency': order.currency,
      'name': 'Fixly',
      'order_id': order.orderId,
      'description': description,
      if (customerName != null && customerName.isNotEmpty)
        'prefill': {
          'name': customerName,
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'contact': phone,
        },
      'theme': {'color': '#01668F'},
    };

    _razorpay!.open(options);
    return completer.future;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
