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

  Future<void> _fetchInvites() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/user/invites/$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _invites = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _respond(String requestId, String teamId, String status) async {
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
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted' ? "Welcome to the team! 🎉" : "Invite declined"),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.grey,
        ));
        _fetchInvites(); // Refresh list
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inbox & Invites")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invites.isEmpty
          ? const Center(child: Text("No pending invites."))
          : ListView.builder(
        itemCount: _invites.length,
        itemBuilder: (context, index) {
          final invite = _invites[index];
          final team = invite['teams']; // Access joined data

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Invite from ${team['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(team['description'] ?? "No description", style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _respond(invite['id'], team['id'], 'rejected'),
                        child: const Text("Decline", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respond(invite['id'], team['id'], 'accepted'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                        child: const Text("Accept & Join"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}