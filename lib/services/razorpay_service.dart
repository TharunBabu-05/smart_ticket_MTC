import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static late Razorpay _razorpay;
  static Function(String)? _onSuccess;
  static Function(String)? _onError;
  
  // Initialize Razorpay
  static void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Payment Configuration
  static const String _keyId = "rzp_test_kb9zv8pio1Wqr1"; // Replace with your actual key
  static const String _keySecret = "ZxaObmBsJ9nGZobfysaZxD9l"; // Replace with your actual secret
  
  // Create Order
  static Future<Map<String, dynamic>?> createOrder({
    required double amount,
    required String currency,
    required String receipt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_keyId:$_keySecret'))}'
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Amount in paisa
          'currency': currency,
          'receipt': receipt,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to create order: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Start Payment
  static void openPayment({
    required String orderId,
    required double amount,
    required String name,
    required String description,
    required String contact,
    required String email,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    var options = {
      'key': _keyId,
      'order_id': orderId,
      'amount': (amount * 100).toInt(), // Amount in paisa
      'name': 'Smart Ticket MTC',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
        'name': name,
      },
      'theme': {
        'color': '#2E7D32', // Green theme matching app
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _onError?.call('Error opening payment: $e');
    }
  }

  // Payment Success Handler
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    String paymentId = response.paymentId ?? '';
    _onSuccess?.call(paymentId);
  }

  // Payment Error Handler
  static void _handlePaymentError(PaymentFailureResponse response) {
    String error = response.message ?? 'Payment failed';
    _onError?.call(error);
  }

  // External Wallet Handler
  static void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    print('External Wallet: ${response.walletName}');
  }

  // Verify Payment (Optional - for server-side verification)
  static bool verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    String generatedSignature = _generateSignature(orderId, paymentId);
    return generatedSignature == signature;
  }

  // Generate Signature for Verification (Simplified for demo)
  static String _generateSignature(String orderId, String paymentId) {
    // In production, implement proper HMAC-SHA256
    // For now, return a simple hash for demo purposes
    return '$orderId|$paymentId'.hashCode.toString();
  }

  // Dispose
  static void dispose() {
    _razorpay.clear();
  }

  // Quick Payment Method for Ticket Booking
  static Future<void> payForTicket({
    required BuildContext context,
    required double ticketPrice,
    required String ticketType,
    required String fromStation,
    required String toStation,
    required String userName,
    required String userEmail,
    required String userPhone,
    required Function(String paymentId) onPaymentSuccess,
    required Function(String error) onPaymentFailure,
  }) async {
    try {
      // Create order
      String receipt = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
      Map<String, dynamic>? order = await createOrder(
        amount: ticketPrice,
        currency: 'INR',
        receipt: receipt,
      );

      if (order != null && order['id'] != null) {
        // Open payment
        openPayment(
          orderId: order['id'],
          amount: ticketPrice,
          name: userName,
          description: 'Smart Ticket: $fromStation → $toStation ($ticketType)',
          contact: userPhone,
          email: userEmail,
          onSuccess: onPaymentSuccess,
          onError: onPaymentFailure,
        );
      } else {
        onPaymentFailure('Failed to create payment order');
      }
    } catch (e) {
      onPaymentFailure('Payment initialization failed: $e');
    }
  }
}

// Payment Status Model
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? error;
  final DateTime timestamp;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'paymentId': paymentId,
      'orderId': orderId,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      paymentId: json['paymentId'],
      orderId: json['orderId'],
      error: json['error'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
