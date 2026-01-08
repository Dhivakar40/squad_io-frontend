import 'dart:async'; // For TimeoutException
import 'dart:io';    // For SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  // --- 1. Fetch Invites with Error Handling ---
  Future<void> _fetchInvites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/user/invites/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _invites = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load invites");
      }
    } on SocketException {
      _showError("No internet connection.");
    } on TimeoutException {
      _showError("Server timed out.");
    } catch (e) {
      _showError("Something went wrong loading invites.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. Respond Logic ---
  Future<void> _respond(String requestId, String teamId, String status) async {
    // Optimistic UI: Remove it from list immediately to feel fast
    setState(() {
      _invites.removeWhere((invite) => invite['id'] == requestId);
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/invites/respond'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requestId": requestId,
          "status": status, // 'accepted' or 'rejected'
          "userId": userId,
          "teamId": teamId
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'accepted' ? "Welcome to the team! 🎉" : "Invite declined"),
              backgroundColor: status == 'accepted' ? Colors.green : Colors.grey[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // If server fails, refresh to show the item again (undo optimism)
        _fetchInvites();
        _showError("Failed to update status.");
      }
    } catch (e) {
      _fetchInvites(); // Revert on error
      _showError("Connection error. Please try again.");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Inbox & Invites", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // --- 3. Refresh Indicator ---
      body: RefreshIndicator(
        onRefresh: _fetchInvites,
        color: Colors.deepPurple,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : _invites.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _invites.length,
          itemBuilder: (context, index) {
            final invite = _invites[index];
            final team = invite['teams'];
            return _buildInviteCard(invite, team);
          },
        ),
      ),
    );
  }

  // --- Helper: Empty State ---
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even when empty
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "No pending invites",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                "Check back later or apply to teams!",
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper: Modern Invite Card ---
  Widget _buildInviteCard(dynamic invite, dynamic team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              radius: 28,
              child: Text(
                team['name'] != null ? team['name'][0].toUpperCase() : "T",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
              ),
            ),
            title: Text(
              team['name'] ?? "Unknown Team",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                team['description'] ?? "No description provided.",
                style: TextStyle(color: Colors.grey.shade600, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade100),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(invite['id'], team['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Decline"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(invite['id'], team['id'], 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Accept & Join"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}