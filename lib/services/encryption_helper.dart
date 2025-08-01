import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  
  /// Generate a 6-character connection code (like ABC123)
  static String generateConnectionCode() {
    Random random = Random();
    String code = '';
    
    // Generate first 3 letters
    for (int i = 0; i < 3; i++) {
      code += _chars[random.nextInt(26)]; // Only letters A-Z
    }
    
    // Generate last 3 numbers
    for (int i = 0; i < 3; i++) {
      code += _chars[26 + random.nextInt(10)]; // Only numbers 0-9
    }
    
    return code;
  }
  
  /// Create encryption key from connection code
  static String createEncryptionKey(String connectionCode) {
    return md5.convert(utf8.encode('smart_ticket_$connectionCode')).toString();
  }
  
  /// Simple XOR encryption for sensor data
  static String encryptSensorData(Map<String, dynamic> data, String key) {
    try {
      String jsonData = jsonEncode(data);
      List<int> keyBytes = utf8.encode(key);
      List<int> dataBytes = utf8.encode(jsonData);
      
      List<int> encrypted = [];
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return base64.encode(encrypted);
    } catch (e) {
      print('❌ Encryption error: $e');
      return jsonEncode(data); // Fallback to unencrypted
    }
  }
  
  /// Decrypt sensor data
  static Map<String, dynamic>? decryptSensorData(String encryptedData, String key) {
    try {
      List<int> keyBytes = utf8.encode(key);
      List<int> encryptedBytes = base64.decode(encryptedData);
      
      List<int> decrypted = [];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      String jsonData = utf8.decode(decrypted);
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Decryption error: $e');
      return null;
    }
  }
  
  /// Validate connection code format (ABC123)
  static bool isValidConnectionCode(String code) {
    if (code.length != 6) return false;
    
    // Check first 3 characters are letters
    for (int i = 0; i < 3; i++) {
      if (!RegExp(r'[A-Z]').hasMatch(code[i])) return false;
    }
    
    // Check last 3 characters are numbers
    for (int i = 3; i < 6; i++) {
      if (!RegExp(r'[0-9]').hasMatch(code[i])) return false;
    }
    
    return true;
  }
}
