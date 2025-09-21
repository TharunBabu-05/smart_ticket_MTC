import 'package:flutter/material.dart';
import '../services/icp_service.dart';
import '../models/icp_ticket_model.dart';

class ICPIntegrationScreen extends StatefulWidget {
  const ICPIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<ICPIntegrationScreen> createState() => _ICPIntegrationScreenState();
}

class _ICPIntegrationScreenState extends State<ICPIntegrationScreen> {
  final ICPService _icpService = ICPService();
  ICPWallet? _wallet;
  bool _isLoading = true;
  bool _isConnected = false;
  String _userPrincipal = '';

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
        await _authenticateUser();
      }
    } catch (e) {
      print('ICP initialization failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateUser() async {
    try {
      final principal = await _icpService.authenticateWithInternetIdentity();
      if (principal != null) {
        setState(() => _userPrincipal = principal);
        await _loadWallet();
      }
    } catch (e) {
      print('Authentication failed: $e');
    }
  }

  Future<void> _loadWallet() async {
    if (_userPrincipal.isEmpty) return;
    
    try {
      final balance = await _icpService.getICPBalance(_userPrincipal);
      final userData = await _icpService.getUserDataFromChain(_userPrincipal);
      
      setState(() {
        _wallet = ICPWallet(
          principal: _userPrincipal,
          icpBalance: balance,
          tickets: userData?['tickets']?.map<ICPTicket>((t) => ICPTicket.fromJson(t)).toList() ?? [],
          lastUpdated: DateTime.now(),
        );
      });
    } catch (e) {
      print('Failed to load wallet: $e');
    }
  }

  Future<void> _purchaseTicketOnChain(String route, double amount) async {
    if (_userPrincipal.isEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      
      final ticketId = await _icpService.purchaseTicketOnChain(
        route: route,
        fromStop: 'Current Location', // Default from stop
        toStop: 'Destination', // Default to stop
        userId: _userPrincipal,
        amount: amount,
      );
      
      if (ticketId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket purchased on blockchain! ID: $ticketId'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadWallet(); // Refresh wallet
      } else {
        throw Exception('Failed to purchase ticket');
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICP Blockchain Integration'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(colorScheme),
                  const SizedBox(height: 24),
                  
                  if (_isConnected && _userPrincipal.isNotEmpty) ...[
                    _buildWalletSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildTicketsSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildActionsSection(colorScheme),
                  ] else ...[
                    _buildAuthenticationSection(colorScheme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'ICP Network Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected 
                  ? 'Connected to Internet Computer'
                  : 'Not connected to Internet Computer',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            if (_userPrincipal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Principal: ${_userPrincipal.substring(0, 20)}...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Internet Identity Authentication',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with Internet Identity to access decentralized features:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Text('• Secure blockchain-based tickets'),
            const Text('• Decentralized data backup'),
            const Text('• ICP token payments'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _authenticateUser,
                icon: const Icon(Icons.account_circle),
                label: const Text('Connect with Internet Identity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ICP Wallet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ICP Balance',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_wallet?.icpBalance.toStringAsFixed(4) ?? '0.0000'} ICP',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsSection(ColorScheme colorScheme) {
    final activeTickets = _wallet?.activeTickets ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Blockchain Tickets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (activeTickets.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No blockchain tickets yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...activeTickets.map((ticket) => _buildTicketCard(ticket, colorScheme)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(ICPTicket ticket, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.route,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${ticket.fromStop} → ${ticket.toStop}'),
          Text('Price: ${ticket.price} ICP'),
          Text('Valid until: ${ticket.validUntil.toString().split('.')[0]}'),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blockchain Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _purchaseTicketOnChain('Route 1', 0.01),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Purchase Test Ticket (0.01 ICP)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _icpService.storeSafetyDataOnChain(
                    userId: _userPrincipal,
                    emergencyContacts: [],
                    preferences: {'backup_timestamp': DateTime.now().millisecondsSinceEpoch},
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Safety data backed up to blockchain'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.backup),
                label: const Text('Backup Safety Data to Blockchain'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}