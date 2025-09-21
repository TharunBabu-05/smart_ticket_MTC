import 'package:flutter/material.dart';
import '../services/icp_service.dart';

class ICPBlockchainWidget extends StatefulWidget {
  const ICPBlockchainWidget({Key? key}) : super(key: key);

  @override
  State<ICPBlockchainWidget> createState() => _ICPBlockchainWidgetState();
}

class _ICPBlockchainWidgetState extends State<ICPBlockchainWidget> {
  final ICPService _icpService = ICPService();
  bool _isConnected = false;
  bool _isLoading = true;
  Map<String, dynamic>? _walletInfo;

  @override
  void initState() {
    super.initState();
    _initializeICP();
  }

  Future<void> _initializeICP() async {
    setState(() => _isLoading = true);
    
    try {
      final connected = await _icpService.initialize();
      setState(() => _isConnected = connected);
      
      if (connected) {
        await _loadWalletInfo();
      }
    } catch (e) {
      print('ICP initialization failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWalletInfo() async {
    try {
      final walletInfo = await _icpService.getWalletInfo();
      setState(() => _walletInfo = walletInfo);
    } catch (e) {
      print('Failed to load wallet info: $e');
    }
  }

  Future<void> _authenticateUser() async {
    try {
      setState(() => _isLoading = true);
      
      final principal = await _icpService.authenticateWithInternetIdentity();
      if (principal != null) {
        await _loadWalletInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully authenticated with Internet Identity')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep blue
            Color(0xFF3B82F6), // Bright blue
            Color(0xFF1E40AF), // Medium blue
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ICP Blockchain',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Decentralized Ticketing',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isConnected ? 'CONNECTED' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_walletInfo == null)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Connect with Internet Identity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _authenticateUser,
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Authenticate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ICP Balance:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${_walletInfo!['balance']?.toStringAsFixed(4) ?? '0.0000'} ICP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Blockchain Tickets:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${(_walletInfo!['tickets'] as List?)?.length ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Principal: ${_walletInfo!['principal']?.toString().substring(0, 20) ?? ''}...',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}