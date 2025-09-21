import 'package:flutter/material.dart';
import '../services/icp_ticket_service.dart';

class BlockchainTicketDialog extends StatefulWidget {
  final String route;
  final String fromStop;
  final String toStop;
  final double price;
  final String userId;

  const BlockchainTicketDialog({
    Key? key,
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.price,
    required this.userId,
  }) : super(key: key);

  @override
  State<BlockchainTicketDialog> createState() => _BlockchainTicketDialogState();
}

class _BlockchainTicketDialogState extends State<BlockchainTicketDialog> {
  final ICPTicketService _icpTicketService = ICPTicketService();
  bool _useBlockchain = false;
  bool _isLoading = false;
  bool _isICPConnected = false;
  Map<String, dynamic>? _walletInfo;
  double _icpPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _checkICPConnection();
  }

  Future<void> _checkICPConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final connected = await _icpTicketService.isICPConnected();
      setState(() => _isICPConnected = connected);
      
      if (connected) {
        final walletInfo = await _icpTicketService.getWalletInfo();
        final icpPrice = await _icpTicketService.getTicketPriceInICP(widget.price);
        
        setState(() {
          _walletInfo = walletInfo;
          _icpPrice = icpPrice;
        });
      }
    } catch (e) {
      print('Error checking ICP connection: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseTicket() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _icpTicketService.purchaseICPTicket(
        route: widget.route,
        fromStop: widget.fromStop,
        toStop: widget.toStop,
        price: widget.price,
        userId: widget.userId,
        useBlockchain: _useBlockchain,
      );

      if (result != null && result['success'] == true) {
        Navigator.of(context).pop(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _useBlockchain 
                ? 'Blockchain ticket purchased successfully!'
                : 'Regular ticket purchased successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${result?['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.confirmation_number, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Purchase Ticket'),
        ],
      ),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading blockchain information...'),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route: ${widget.route}', 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('From: ${widget.fromStop}'),
                      Text('To: ${widget.toStop}'),
                      const SizedBox(height: 8),
                      Text('Price: ₹${widget.price.toStringAsFixed(2)}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Blockchain option
                if (_isICPConnected) ...[
                  const Text('Payment Options:', 
                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  
                  // Regular payment option
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _useBlockchain,
                      onChanged: (value) => setState(() => _useBlockchain = value!),
                    ),
                    title: const Text('Regular Payment'),
                    subtitle: Text('₹${widget.price.toStringAsFixed(2)} - Standard ticket'),
                  ),
                  
                  // Blockchain payment option
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _useBlockchain,
                      onChanged: (value) => setState(() => _useBlockchain = value!),
                    ),
                    title: Row(
                      children: [
                        const Text('Blockchain Payment'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ICP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_icpPrice.toStringAsFixed(4)} ICP - Immutable & Secure'),
                        if (_walletInfo != null)
                          Text(
                            'Wallet Balance: ${_walletInfo!['balance']?.toStringAsFixed(4) ?? '0.0000'} ICP',
                            style: TextStyle(
                              color: (_walletInfo!['balance'] ?? 0.0) >= _icpPrice 
                                  ? Colors.green 
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  if (_useBlockchain) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.purple[50]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('Blockchain Benefits:', 
                                   style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('• Immutable ticket verification\n'
                               '• Decentralized storage\n'
                               '• Enhanced security\n'
                               '• Global accessibility',
                               style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ICP blockchain is currently offline. Using regular payment.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _purchaseTicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: _useBlockchain ? Colors.blue : Theme.of(context).primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_useBlockchain ? 'Pay with ICP' : 'Purchase'),
        ),
      ],
    );
  }
}