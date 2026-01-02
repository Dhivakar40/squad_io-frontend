import 'package:flutter/material.dart';
import 'package:squad_io/main.dart'; // For TeammateFeed (Path B)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_team_screen.dart'; // We will create this next
import 'inbox_screen.dart';
import 'team_feed_screen.dart';
import 'my_squads_screen.dart';
import 'edit_profile_screen.dart';
import 'team_feed_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Squad.io"),
        actions: [
          // --- INBOX BUTTON (New) ---
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Inbox',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            },
          ),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                // 1. Sign out from Supabase
                await Supabase.instance.client.auth.signOut();

                // 2. Clear navigation stack and return to Login (handled by AuthGate usually, but this forces it)
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
          )

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "What is your goal today?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // PATH A: I AM SOLO -> FIND A TEAM
            _buildOptionCard(
              context,
              icon: Icons.search,
              title: "Join a Team",
              subtitle: "Browse existing teams looking for your skills.",
              color: Colors.blue.shade100,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamFeedScreen()));
              },
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.star_border),
                label: const Text("My Squads"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MySquadsScreen()));
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              icon: Icons.group_add,
              title: "Recruit Teammates",
              subtitle: "Create a team and find students.",
              color: Colors.purple.shade100,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTeamScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54)
          ],
        ),
      ),
    );
  }
}