import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/safety_service.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactsScreen extends StatefulWidget {
  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final SafetyService _safetyService = SafetyService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _safetyService.getEmergencyContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load contacts: $e');
    }
  }

  Future<void> _addContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => AddEditContactDialog(),
    );

    if (result != null) {
      try {
        await _safetyService.addEmergencyContact(result);
        _loadContacts();
        _showSuccessSnackBar('Emergency contact added successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to add contact: $e');
      }
    }
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => AddEditContactDialog(contact: contact),
    );

    if (result != null) {
      try {
        await _safetyService.updateEmergencyContact(result);
        _loadContacts();
        _showSuccessSnackBar('Contact updated successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to update contact: $e');
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final shouldDelete = await _showDeleteConfirmation(contact.name);
    if (shouldDelete == true) {
      try {
        await _safetyService.removeEmergencyContact(contact.id);
        _loadContacts();
        _showSuccessSnackBar('Contact removed successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to remove contact: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header info
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These contacts will be notified when you activate Emergency SOS',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contacts list
                Expanded(
                  child: _contacts.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            return _buildContactCard(_contacts[index], colorScheme);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: Icon(Icons.person_add),
        label: Text('Add Contact'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 24),
            Text(
              'No emergency contacts added',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Add trusted contacts who will be notified\nwhen you activate Emergency SOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addContact,
              icon: Icon(Icons.person_add),
              label: Text('Add First Contact'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            contact.getRelationshipIcon(),
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              contact.getFormattedPhoneNumber(),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 2),
            Text(
              contact.relationship,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editContact(contact);
                break;
              case 'delete':
                _deleteContact(contact);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(String contactName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Contact'),
        content: Text(
          'Are you sure you want to remove $contactName from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }
}

class AddEditContactDialog extends StatefulWidget {
  final EmergencyContact? contact;

  AddEditContactDialog({this.contact});

  @override
  _AddEditContactDialogState createState() => _AddEditContactDialogState();
}

class _AddEditContactDialogState extends State<AddEditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRelationship = 'Family';

  final List<String> _relationships = [
    'Family',
    'Friend',
    'Spouse',
    'Parent',
    'Sibling',
    'Child',
    'Colleague',
    'Doctor',
    'Emergency Service',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _emailController.text = widget.contact!.email;
      _selectedRelationship = widget.contact!.relationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Contact' : 'Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: '+91 98765 43210',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
                // Simple phone number validation
                final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
                if (!phoneRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid phone number';
                }
                if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (Optional)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                hintText: 'contact@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Simple email validation if provided
                  final emailRegex = RegExp(r'^[\w\-\.]+@[\w\-\.]+\.[\w]+$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
              items: _relationships.map((relationship) {
                return DropdownMenuItem(
                  value: relationship,
                  child: Text(relationship),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRelationship = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final contact = EmergencyContact(
        id: widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        relationship: _selectedRelationship,
        createdAt: widget.contact?.createdAt ?? DateTime.now(),
      );
      
      Navigator.pop(context, contact);
    }
  }
}