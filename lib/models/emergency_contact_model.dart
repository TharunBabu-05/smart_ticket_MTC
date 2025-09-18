import 'package:flutter/material.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String relationship;
  final bool isPrimary;
  final bool canReceiveAlerts;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.relationship,
    this.isPrimary = false,
    this.canReceiveAlerts = true,
    required this.createdAt,
  });

  // Factory constructor for creating from JSON
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      relationship: json['relationship'] ?? 'Friend',
      isPrimary: json['isPrimary'] ?? false,
      canReceiveAlerts: json['canReceiveAlerts'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'canReceiveAlerts': canReceiveAlerts,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Copy with changes
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
    bool? canReceiveAlerts,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      canReceiveAlerts: canReceiveAlerts ?? this.canReceiveAlerts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmergencyContact{id: $id, name: $name, phoneNumber: $phoneNumber, relationship: $relationship}';
  }

  // Validation methods
  bool get isValid {
    return name.trim().isNotEmpty && 
           phoneNumber.trim().isNotEmpty && 
           _isValidPhoneNumber(phoneNumber);
  }

  bool _isValidPhoneNumber(String phone) {
    // Simple validation for Indian phone numbers
    final phoneRegex = RegExp(r'^[+]?[0-9]{10,13}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  bool get isValidEmail {
    if (email.isEmpty) return true; // Email is optional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Helper methods
  String get formattedPhoneNumber {
    String phone = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    }
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phoneNumber;
  }

  String get displayName {
    return '$name${isPrimary ? ' (Primary)' : ''}';
  }

  String get relationshipIcon {
    switch (relationship.toLowerCase()) {
      case 'mother':
      case 'father':
      case 'parent':
        return '👨‍👩‍👧‍👦';
      case 'brother':
      case 'sister':
      case 'sibling':
        return '👫';
      case 'friend':
        return '👯';
      case 'spouse':
      case 'husband':
      case 'wife':
        return '💑';
      case 'colleague':
        return '👔';
      case 'neighbor':
        return '🏠';
      default:
        return '👤';
    }
  }

  // Alternative method names for compatibility
  IconData getRelationshipIcon() {
    switch (relationship.toLowerCase()) {
      case 'family':
      case 'mother':
      case 'father':
      case 'parent':
        return Icons.family_restroom;
      case 'brother':
      case 'sister':
      case 'sibling':
        return Icons.people;
      case 'friend':
        return Icons.people_outline;
      case 'spouse':
      case 'husband':
      case 'wife':
        return Icons.favorite;
      case 'colleague':
        return Icons.work;
      case 'child':
        return Icons.child_care;
      case 'doctor':
        return Icons.medical_services;
      case 'emergency service':
        return Icons.emergency;
      default:
        return Icons.person;
    }
  }

  String getFormattedPhoneNumber() {
    return formattedPhoneNumber;
  }
}