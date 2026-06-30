import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.instance.getUserProfile();
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    if (mounted) {
      setState(() {
        _profile = profile != null ? Map<String, dynamic>.from(profile) : {};
        _profile!['uni_name'] = meta['uni_name'] ?? _profile!['uni_name'];
        _profile!['major'] = meta['major'] ?? _profile!['major'];
        _profile!['company'] = meta['company'] ?? _profile!['company'];
        _profile!['full_name'] = meta['full_name'] ?? meta['name'] ?? _profile!['full_name'];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    if (_profile == null) return;

    DateTime? initialDate;
    if (_profile!['training_start_date'] != null) {
      initialDate = DateTime.tryParse(_profile!['training_start_date'].toString());
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      try {
        final isoDate = selectedDate.toIso8601String().split('T').first; // Just YYYY-MM-DD
        await SupabaseService.instance.updateProfile({
          'training_start_date': isoDate,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training Start Date updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Refresh local state to update the UI
        _loadProfile();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update date: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found.'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.account_circle, size: 100, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _profile!['full_name'] ?? 'Unknown User',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.school),
                            title: const Text('University'),
                            subtitle: Text(_profile!['uni_name'] ?? 'Not set'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.book),
                            title: const Text('Major'),
                            subtitle: Text(_profile!['major'] ?? 'Not set'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Company'),
                            subtitle: Text(_profile!['company'] ?? 'Not set'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Training Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(100), width: 2),
                      ),
                      child: ListTile(
                        onTap: _selectStartDate,
                        leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Set Training Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _profile!['training_start_date'] != null
                              ? DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_profile!['training_start_date'].toString()))
                              : 'Not set (Required for Timeline)',
                          style: TextStyle(
                            color: _profile!['training_start_date'] != null ? Colors.black87 : Colors.orange,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
    );
  }
}
