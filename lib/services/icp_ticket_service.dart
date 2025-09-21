import '../services/icp_service.dart';
import '../services/enhanced_ticket_service.dart';

class ICPTicketService {
  static final ICPTicketService _instance = ICPTicketService._internal();
  factory ICPTicketService() => _instance;
  ICPTicketService._internal();

  final ICPService _icpService = ICPService();

  // Purchase ticket with blockchain integration
  Future<Map<String, dynamic>?> purchaseICPTicket({
    required String route,
    required String fromStop,
    required String toStop,
    required double price,
    required String userId,
    required bool useBlockchain,
  }) async {
    try {
      if (useBlockchain) {
        // First authenticate user if not already done
        final principal = await _icpService.authenticateWithInternetIdentity();
        if (principal == null) {
          throw Exception('Blockchain authentication required');
        }

        // Purchase on blockchain
        final blockchainResult = await _icpService.purchaseBlockchainTicket(
          route: route,
          fromStop: fromStop,
          toStop: toStop,
          amount: price,
          userId: userId,
        );

        if (blockchainResult != null) {
          // Also create regular ticket for offline use
          final regularTicket = await EnhancedTicketService.issueTicket(
            sourceName: fromStop,
            destinationName: toStop,
            fare: price,
            paymentId: blockchainResult['transaction_hash'],
          );

          return {
            'success': true,
            'ticket_id': blockchainResult['id'],
            'transaction_hash': blockchainResult['transaction_hash'],
            'blockchain_ticket': blockchainResult,
            'regular_ticket': regularTicket,
            'type': 'blockchain',
          };
        } else {
          throw Exception('Blockchain transaction failed');
        }
      } else {
        // Regular ticket purchase
        final ticket = await EnhancedTicketService.issueTicket(
          sourceName: fromStop,
          destinationName: toStop,
          fare: price,
          paymentId: 'regular_${DateTime.now().millisecondsSinceEpoch}',
        );

        return {
          'success': true,
          'ticket': ticket,
          'type': 'regular',
        };
      }
    } catch (e) {
      print('Error purchasing ICP ticket: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Validate ticket with blockchain verification
  Future<Map<String, dynamic>> validateTicket({
    required String ticketId,
    required bool isBlockchainTicket,
  }) async {
    try {
      if (isBlockchainTicket) {
        // Validate on blockchain first
        final blockchainValid = await _icpService.validateTicketOnChain(ticketId);
        
        // Also validate locally as backup
        final ticket = await EnhancedTicketService.getTicketById(ticketId);
        final localValid = ticket != null;

        return {
          'is_valid': blockchainValid && localValid,
          'blockchain_verified': blockchainValid,
          'local_verified': localValid,
          'type': 'blockchain',
        };
      } else {
        // Regular validation
        final ticket = await EnhancedTicketService.getTicketById(ticketId);
        final isValid = ticket != null;
        
        return {
          'is_valid': isValid,
          'type': 'regular',
        };
      }
    } catch (e) {
      print('Error validating ticket: $e');
      return {
        'is_valid': false,
        'error': e.toString(),
      };
    }
  }

  // Get user's blockchain tickets
  Future<List<Map<String, dynamic>>> getUserBlockchainTickets() async {
    try {
      return await _icpService.getUserTickets();
    } catch (e) {
      print('Error getting blockchain tickets: $e');
      return [];
    }
  }

  // Get ICP wallet information
  Future<Map<String, dynamic>?> getWalletInfo() async {
    try {
      return await _icpService.getWalletInfo();
    } catch (e) {
      print('Error getting wallet info: $e');
      return null;
    }
  }

  // Check ICP service connection
  Future<bool> isICPConnected() async {
    try {
      return await _icpService.initialize();
    } catch (e) {
      print('ICP connection check failed: $e');
      return false;
    }
  }

  // Authenticate with Internet Identity
  Future<String?> authenticateUser() async {
    try {
      return await _icpService.authenticateWithInternetIdentity();
    } catch (e) {
      print('Authentication failed: $e');
      return null;
    }
  }

  // Transfer ICP tokens
  Future<bool> transferICP({
    required String fromPrincipal,
    required String toPrincipal,
    required double amount,
  }) async {
    try {
      return await _icpService.transferICP(
        fromPrincipal: fromPrincipal,
        toPrincipal: toPrincipal,
        amount: amount,
      );
    } catch (e) {
      print('ICP transfer failed: $e');
      return false;
    }
  }

  // Store safety data on blockchain
  Future<bool> storeSafetyDataOnChain({
    required String userId,
    required List<Map<String, dynamic>> emergencyContacts,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      return await _icpService.storeSafetyDataOnChain(
        userId: userId,
        emergencyContacts: emergencyContacts,
        preferences: preferences,
      );
    } catch (e) {
      print('Error storing safety data on blockchain: $e');
      return false;
    }
  }

  // Get ticket price in ICP
  Future<double> getTicketPriceInICP(double usdPrice) async {
    try {
      // In a real implementation, get current ICP/USD exchange rate
      // For now, use a mock rate
      const double icpToUsd = 5.0; // 1 ICP = $5 USD (example)
      return usdPrice / icpToUsd;
    } catch (e) {
      print('Error calculating ICP price: $e');
      return 0.0;
    }
  }
}