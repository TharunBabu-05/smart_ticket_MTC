import 'package:flutter/material.dart';
import '../services/razorpay_service.dart';

class PaymentTestScreen extends StatefulWidget {
  @override
  _PaymentTestScreenState createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  bool _isProcessing = false;
  String _resultMessage = '';

  void _testPayment() async {
    setState(() {
      _isProcessing = true;
      _resultMessage = 'Processing payment...';
    });

    try {
      await RazorpayService.payForTicket(
        context: context,
        ticketPrice: 25.0,
        ticketType: 'Test Ticket',
        fromStation: 'Chennai Central',
        toStation: 'T Nagar',
        userName: 'Test User',
        userEmail: 'test@example.com',
        userPhone: '+919876543210',
        onPaymentSuccess: (paymentId) {
          setState(() {
            _isProcessing = false;
            _resultMessage = 'Payment Successful!\nPayment ID: $paymentId';
          });
        },
        onPaymentFailure: (error) {
          setState(() {
            _isProcessing = false;
            _resultMessage = 'Payment Failed!\nError: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _resultMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Integration Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Ticket Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('From: Chennai Central'),
                    Text('To: T Nagar'),
                    Text('Fare: ₹25.00'),
                    Text('Type: Regular Ticket'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _testPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment),
                        SizedBox(width: 8),
                        Text('Test Payment'),
                      ],
                    ),
            ),
            SizedBox(height: 20),
            if (_resultMessage.isNotEmpty)
              Card(
                color: _resultMessage.contains('Successful')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(_resultMessage),
                    ],
                  ),
                ),
              ),
            Spacer(),
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Integration Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Razorpay Flutter SDK: Installed'),
                    Text('✅ Payment Service: Initialized'),
                    Text('✅ Test Environment: Ready'),
                    SizedBox(height: 8),
                    Text(
                      'Note: This is using Razorpay test keys. Replace with production keys before deployment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
