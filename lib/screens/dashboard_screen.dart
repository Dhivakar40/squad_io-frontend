import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_team_screen.dart';
import 'inbox_screen.dart';
import 'team_feed_screen.dart';
import 'my_squads_screen.dart';
import 'edit_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "Student"; // Default placeholder
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userName = data['full_name'] ?? "Student";
            _isLoadingName = false;
          });
        }
      }
    } catch (e) {
      // If error (e.g., network), keep default "Student"
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Row(
          children: [
            // --- LOGO CHANGE HERE ---
            Image.asset(
              'assets/logo-icon.ico',
              height: 32, // Adjusted size to fit AppBar
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              "Squad.io",
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          _buildAppBarIcon(
            context,
            icon: Icons.notifications_outlined,
            tooltip: "Inbox",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen())),
          ),
          _buildAppBarIcon(
            context,
            icon: Icons.person_outline,
            tooltip: "Profile",
            onTap: () async {
              // Wait for edit screen to close, then refresh name in case it changed
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _fetchUserName();
            },
          ),
          _buildAppBarIcon(
            context,
            icon: Icons.logout,
            tooltip: "Logout",
            isDestructive: true,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GREETING SECTION ---
            Text(
              "Welcome back,",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            // Animated Switcher for smooth text loading
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoadingName
                  ? Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 150,
                  height: 30,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )
                  : Text(
                _userName,
                key: ValueKey(_userName), // Ensures animation runs on change
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- FEATURED CARD: MY SQUADS ---
            _buildMySquadsBanner(context),

            const SizedBox(height: 32),

            // --- SECTION TITLE ---
            const Text(
              "Get Started",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // --- ACTION GRID (Join vs Create) ---
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: "Find a\nTeam",
                    icon: Icons.search,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamFeedScreen())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: "Create\nSquad",
                    icon: Icons.add_circle_outline,
                    color: Colors.deepPurpleAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTeamScreen())),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- TIP SECTION ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Tip: Complete your profile to get better team matches!",
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAppBarIcon(BuildContext context, {required IconData icon, required VoidCallback onTap, required String tooltip, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: isDestructive ? Colors.red.shade400 : Colors.black87),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildMySquadsBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySquadsScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.shade200.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "ACTIVE DASHBOARD",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "My Squads",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage your teams & chats",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}