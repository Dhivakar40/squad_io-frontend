import 'dart:async'; // Required for TimeoutException
import 'dart:io';    // Required for SocketException
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _skillController = TextEditingController();

  // State Variables
  String? _selectedDept;
  String? _selectedYear;
  List<String> _skills = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Constants
  final List<String> _departments = [
    'CSE', 'IT', 'AIDS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'BME', 'MCTS'
  ];
  final List<String> _years = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // --- Helper to show consistent error messages ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- 1. LOAD DATA WITH ROBUST ERROR HANDLING ---
  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Added .timeout() to prevent infinite loading screens
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _githubController.text = data['github'] ?? '';
          _linkedinController.text = data['linkedin'] ?? '';

          if (_departments.contains(data['department'])) {
            _selectedDept = data['department'];
          }

          String? incomingYear = data['year']?.toString();
          if (_years.contains(incomingYear)) {
            _selectedYear = incomingYear;
          } else {
            _selectedYear = null;
          }

          if (data['skills'] != null) {
            _skills = List<String>.from(data['skills']);
          }

          _isLoading = false;
        });
      }
    } on SocketException {
      // Handle No Internet
      _showError("No internet connection. Please check your settings.");
      if (mounted) setState(() => _isLoading = false);
    } on TimeoutException {
      // Handle Slow Server
      _showError("Server timed out. Please try again later.");
      if (mounted) setState(() => _isLoading = false);
    } on PostgrestException catch (e) {
      // Handle Database Errors (like missing columns)
      _showError("Database Error: ${e.message}");
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      // Handle Unknown Errors
      _showError("An unexpected error occurred.");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. SAVE DATA WITH ROBUST ERROR HANDLING ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('users').update({
        'full_name': _nameController.text.trim(),
        'department': _selectedDept,
        'year': _selectedYear,
        'bio': _bioController.text.trim(),
        'github': _githubController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'skills': _skills,
      }).eq('id', user.id).timeout(const Duration(seconds: 10));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Profile Saved Successfully!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on SocketException {
      _showError("No internet connection. Changes not saved.");
    } on TimeoutException {
      _showError("Request timed out. Please check your connection.");
    } on PostgrestException catch (e) {
      _showError("Database Error: ${e.message}");
    } catch (e) {
      _showError("Failed to save changes. Please try again.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Logic for adding skills
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Avatar Section ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                            fontSize: 40,
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Personal Details ---
              _buildSectionTitle("PERSONAL DETAILS"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedDept,
                            label: "Dept",
                            items: _departments,
                            onChanged: (v) => setState(() => _selectedDept = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedYear,
                            label: "Year",
                            items: _years,
                            onChanged: (v) => setState(() => _selectedYear = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Professional Info ---
              _buildSectionTitle("PROFESSIONAL INFO"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _skillController,
                      decoration: InputDecoration(
                        labelText: "Add Skills",
                        hintText: "e.g. Java, SQL",
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.bolt, color: Colors.orange),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                          onPressed: _addSkill,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                    const SizedBox(height: 12),
                    if (_skills.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _skills.map((skill) => Chip(
                          label: Text(skill, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.deepPurple.shade50,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeSkill(skill),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        )).toList(),
                      ),
                    if (_skills.isNotEmpty) const SizedBox(height: 20),
                    _buildTextField(
                      controller: _bioController,
                      label: "Bio",
                      icon: Icons.edit_note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Social Links ---
              _buildSectionTitle("SOCIAL LINKS"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _githubController,
                      label: "GitHub URL",
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _linkedinController,
                      label: "LinkedIn URL",
                      icon: Icons.business,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Save Button ---
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required IconData icon,
        int maxLines = 1,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(
      {required String? value,
        required String label,
        required List<String> items,
        required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}