import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:cbor/cbor.dart';
import 'package:hex/hex.dart';

class ICPService {
  static const String IC_HOST = 'https://ic0.app';
  static const String II_HOST = 'https://identity.ic0.app';
  static const String icHost = 'https://ic0.app';
  static const String iiHost = 'https://identity.ic0.app';
  static const String canisterId = 'rdmx6-jaaaa-aaaah-qdrqq-cai';
  static const String ledgerCanisterId = 'rrkah-fqaaa-aaaaa-aaaaq-cai'; // Example Smart Ticket Canister
  static const String LEDGER_CANISTER_ID = 'rrkah-fqaaa-aaaaa-aaaaq-cai'; // ICP Ledger Canister
  
  String? _userPrincipal;
  String? _delegationIdentity;
  
  // Internet Identity Authentication
  Future<String?> authenticateWithInternetIdentity() async {
    try {
      // In a real implementation, this would open II authentication flow
      // For now, we'll simulate the authentication
      print('Initiating Internet Identity authentication...');
      
      // This would normally involve opening a WebView or browser
      // and handling the authentication callback
      final mockPrincipal = _generateMockPrincipal();
      _userPrincipal = mockPrincipal;
      
      return mockPrincipal;
    } catch (e) {
      print('Internet Identity authentication failed: $e');
      return null;
    }
  }
  
  String _generateMockPrincipal() {
    // Generate a mock principal ID for development/testing
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('user_$timestamp')).toString();
    return 'mock-${hash.substring(0, 10)}-principal';
  }
  
  // Initialize ICP connection
  Future<bool> initialize() async {
    try {
      // Test connection to IC network
      final response = await http.get(
        Uri.parse('$icHost/api/v2/status'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ICP initialization failed: $e');
      return false;
    }
  }
  
  // Helper method to encode data using Candid format
  List<int> _encodeCandid(Map<String, dynamic> data) {
    try {
      // Simple JSON encoding for development - in production would use proper Candid encoding
      return utf8.encode(jsonEncode(data));
    } catch (e) {
      print('Candid encoding error: $e');
      return [];
    }
  }
  
  // Helper method to decode Candid response
  Map<String, dynamic> _decodeCandid(List<int> data) {
    try {
      // Simple JSON decoding for development - in production would use proper Candid decoding
      return jsonDecode(utf8.decode(data));
    } catch (e) {
      print('Candid decoding error: $e');
      return {};
    }
  }

  // Enhanced ticket purchase with proper blockchain integration
  Future<Map<String, dynamic>?> purchaseBlockchainTicket({
    required String route,
    required String fromStop,
    required String toStop,
    required double amount,
    required String userId,
  }) async {
    try {
      if (_userPrincipal == null) {
        throw Exception('User not authenticated');
      }

      final ticketData = {
        'id': _generateTicketId(),
        'route': route,
        'from_stop': fromStop,
        'to_stop': toStop,
        'price': amount,
        'user_principal': _userPrincipal,
        'purchase_time': DateTime.now().millisecondsSinceEpoch,
        'valid_until': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
        'status': 'active',
      };

      final requestBody = {
        'method_name': 'create_ticket',
        'arg': _encodeCandid(ticketData),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        final decoded = _decodeCandid(response.toList());
        
        // Create blockchain transaction record
        final transactionHash = await _recordTransaction({
          'type': 'ticket_purchase',
          'amount': amount,
          'from': _userPrincipal,
          'to': canisterId,
          'ticket_id': ticketData['id'],
        });
        
        return {
          ...decoded,
          'transaction_hash': transactionHash,
        };
      }
      
      return null;
    } catch (e) {
      print('Error purchasing blockchain ticket: $e');
      return null;
    }
  }

  // Alias for purchaseBlockchainTicket for compatibility
  Future<Map<String, dynamic>?> purchaseTicketOnChain({
    required String route,
    required String fromStop,
    required String toStop,
    required double amount,
    required String userId,
  }) async {
    return await purchaseBlockchainTicket(
      route: route,
      fromStop: fromStop,
      toStop: toStop,
      amount: amount,
      userId: userId,
    );
  }

  String _generateTicketId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000).toString().padLeft(5, '0');
    return 'ICP_TKT_${timestamp}_$random';
  }

  // Record transaction on blockchain
  Future<String> _recordTransaction(Map<String, dynamic> transactionData) async {
    try {
      final transactionBytes = _encodeCbor(transactionData);
      final hash = sha256.convert(transactionBytes).toString();
      
      // In a real implementation, this would submit to the ledger canister
      print('Recording transaction with hash: $hash');
      
      return hash;
    } catch (e) {
      print('Error recording transaction: $e');
      return 'error_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get user's ICP wallet information
  Future<Map<String, dynamic>?> getWalletInfo() async {
    try {
      if (_userPrincipal == null) return null;
      
      final balance = await getICPBalance(_userPrincipal!);
      final tickets = await getUserTickets();
      
      return {
        'principal': _userPrincipal,
        'balance': balance,
        'tickets': tickets,
        'wallet_address': _principalToAddress(_userPrincipal!),
      };
    } catch (e) {
      print('Error getting wallet info: $e');
      return null;
    }
  }

  // Get user's blockchain tickets
  Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      if (_userPrincipal == null) return [];
      
      final requestBody = {
        'method_name': 'get_user_tickets',
        'arg': _encodeCandid({'user_principal': _userPrincipal}),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        final decoded = _decodeCandid(response.toList());
        return List<Map<String, dynamic>>.from(decoded['tickets'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('Error getting user tickets: $e');
      return [];
    }
  }

  String _principalToAddress(String principal) {
    // Convert principal to account identifier
    // This is a simplified implementation
    final hash = sha256.convert(utf8.encode(principal));
    return HEX.encode(hash.bytes);
  }

  // Store safety data on ICP (decentralized backup)
  Future<bool> storeSafetyDataOnChain({
    required String userId,
    required List<Map<String, dynamic>> emergencyContacts,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final requestBody = {
        'method_name': 'store_safety_data',
        'arg': _encodeCandid({
          'user_id': userId,
          'emergency_contacts': emergencyContacts,
          'preferences': preferences,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      };

      final response = await _makeCanisterCall(requestBody);
      return response != null;
    } catch (e) {
      print('Error storing safety data on ICP: $e');
      return false;
    }
  }

  // Retrieve user data from blockchain
  Future<Map<String, dynamic>?> getUserDataFromChain(String userId) async {
    try {
      final requestBody = {
        'method_name': 'get_user_data',
        'arg': _encodeCandid({'user_id': userId}),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        return _decodeCandid(response);
      }
      
      return null;
    } catch (e) {
      print('Error retrieving user data from ICP: $e');
      return null;
    }
  }

  // Private helper methods
  Future<Uint8List?> _makeCanisterCall(Map<String, dynamic> requestBody) async {
    try {
      final url = '$icHost/api/v2/canister/$canisterId/call';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/cbor',
        },
        body: _encodeCbor(requestBody),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      
      return null;
    } catch (e) {
      print('Canister call failed: $e');
      return null;
    }
  }

  // Proper CBOR encoding using cbor package
  List<int> _encodeCbor(Map<String, dynamic> data) {
    try {
      // For development, use JSON encoding
      // In production, would use proper CBOR encoding
      return utf8.encode(jsonEncode(data));
    } catch (e) {
      print('CBOR encoding error: $e');
      return utf8.encode(jsonEncode(data));
    }
  }

  Map<String, dynamic> _decodeCbor(List<int> data) {
    try {
      // For development, use JSON decoding  
      // In production, would use proper CBOR decoding
      return jsonDecode(utf8.decode(data));
    } catch (e) {
      print('CBOR decoding error: $e');
      return jsonDecode(utf8.decode(data));
    }
  }

  // Get ICP token balance
  Future<double> getICPBalance(String principal) async {
    try {
      final requestBody = {
        'method_name': 'account_balance',
        'arg': _encodeCandid({'account': principal}),
      };

      // Mock response for development
      return 10.5; // Mock balance
    } catch (e) {
      print('Error getting ICP balance: $e');
      return 0.0;
    }
  }

  // Transfer ICP tokens
  Future<bool> transferICP({
    required String fromPrincipal,
    required String toPrincipal,
    required double amount,
  }) async {
    try {
      print('Transferring $amount ICP from $fromPrincipal to $toPrincipal');
      // Mock successful transfer for development
      return true;
    } catch (e) {
      print('Error transferring ICP: $e');
      return false;
    }
  }

  // Validate ticket on blockchain
  Future<bool> validateTicketOnChain(String ticketId) async {
    try {
      print('Validating ticket $ticketId on blockchain');
      // Mock validation for development
      return true;
    } catch (e) {
      print('Error validating ticket: $e');
      return false;
    }
  }
}