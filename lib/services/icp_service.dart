import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ICPService {
  static const String IC_HOST = 'https://ic0.app';
  static const String CANISTER_ID = 'your-canister-id-here';
  
  // Initialize ICP connection
  Future<bool> initialize() async {
    try {
      // Test connection to IC network
      final response = await http.get(
        Uri.parse('$IC_HOST/api/v2/status'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('ICP initialization failed: $e');
      return false;
    }
  }

  // Purchase ticket on ICP blockchain
  Future<String?> purchaseTicketOnChain({
    required String route,
    required String userId,
    required double amount,
  }) async {
    try {
      final requestBody = {
        'method_name': 'purchase_ticket',
        'arg': _encodeCandid({
          'route': route,
          'user_id': userId,
          'amount': amount,
        }),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        final decoded = _decodeCandid(response);
        return decoded['ticket_id'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error purchasing ticket on ICP: $e');
      return null;
    }
  }

  // Validate ticket on blockchain
  Future<bool> validateTicketOnChain(String ticketId) async {
    try {
      final requestBody = {
        'method_name': 'validate_ticket',
        'arg': _encodeCandid({'ticket_id': ticketId}),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        final decoded = _decodeCandid(response);
        return decoded['is_valid'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error validating ticket on ICP: $e');
      return false;
    }
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

  // Internet Identity integration
  Future<String?> authenticateWithInternetIdentity() async {
    try {
      // This would integrate with Internet Identity
      // For now, returning a mock principal
      return 'mock-principal-id';
    } catch (e) {
      print('Internet Identity authentication failed: $e');
      return null;
    }
  }

  // Private helper methods
  Future<Uint8List?> _makeCanisterCall(Map<String, dynamic> requestBody) async {
    try {
      final url = '$IC_HOST/api/v2/canister/$CANISTER_ID/call';
      
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

  Uint8List _encodeCandid(Map<String, dynamic> data) {
    // Simplified Candid encoding - in real implementation use proper Candid library
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  Map<String, dynamic> _decodeCandid(Uint8List data) {
    // Simplified Candid decoding - in real implementation use proper Candid library
    return jsonDecode(utf8.decode(data));
  }

  Uint8List _encodeCbor(Map<String, dynamic> data) {
    // Simplified CBOR encoding - use proper CBOR library
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  // Get ICP token balance
  Future<double> getICPBalance(String principal) async {
    try {
      final requestBody = {
        'method_name': 'account_balance',
        'arg': _encodeCandid({'account': principal}),
      };

      final response = await _makeCanisterCall(requestBody);
      
      if (response != null) {
        final decoded = _decodeCandid(response);
        return (decoded['balance'] as num?)?.toDouble() ?? 0.0;
      }
      
      return 0.0;
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
      final requestBody = {
        'method_name': 'transfer',
        'arg': _encodeCandid({
          'from': fromPrincipal,
          'to': toPrincipal,
          'amount': amount,
        }),
      };

      final response = await _makeCanisterCall(requestBody);
      return response != null;
    } catch (e) {
      print('Error transferring ICP: $e');
      return false;
    }
  }
}