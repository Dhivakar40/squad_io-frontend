import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  // NOTE: _deptController removed because we use a Dropdown now
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _resumeController = TextEditingController();

  bool _isLoading = false;
  int? _selectedYear;
  String? _selectedDept; // Stores the selected department
  bool _isLookingForTeam = true;

  // --- ANIMATION STATE ---
  late AnimationController _animController;
  final List<ConnectionParticle> _particles = [];
  final Random _rng = Random();

  // --- IMAGE PICKER STATE ---
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // --- AVATAR EMOJI DATA ---
  final List<String> _animalAvatars = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆',
    '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋',
    '🐌', '🐞', '🐜', '🦟', '🐢', '🐍', '🦎', '🐙', '🦑', '🦐',
    '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊'
  ];
  String? _selectedAvatarEmoji;

  // --- DATA LISTS ---
  // 1. Departments List (From your screenshot)
  final List<String> _departments = [
    'CSE', 'IT', 'AIDS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'BME', 'MCTS'
  ];

  // 2. Skills List
  final List<String> _allSkills = [
    'Flutter', 'React', 'Python', 'Node.js', 'Java', 'C++', 'C#', 'Go', 'Swift', 'Kotlin', 'Rust', 'Dart',
    'SQL', 'NoSQL', 'MongoDB', 'PostgreSQL', 'Firebase', 'Supabase', 'AWS', 'Docker', 'Kubernetes',
    'Figma', 'Adobe XD', 'Machine Learning', 'Data Science', 'TensorFlow', 'NLP',
    'Project Management', 'Agile', 'Marketing', 'SEO', 'Content Writing', 'Video Editing'
  ];

  final Set<String> _selectedSkills = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    for (int i = 0; i < 25; i++) {
      _particles.add(ConnectionParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.002,
        vy: (_rng.nextDouble() - 0.5) * 0.002,
      ));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    // _deptController.dispose(); // Removed
    _bioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _resumeController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
        _selectedAvatarEmoji = null;
      });
    }
  }

  void _addCustomSkill() {
    TextEditingController customSkillController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Skill"),
        content: TextField(
          controller: customSkillController,
          decoration: const InputDecoration(hintText: "Enter skill name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (customSkillController.text.isNotEmpty) {
                setState(() {
                  if (_selectedSkills.length < 5) {
                    _selectedSkills.add(customSkillController.text.trim());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 5 skills allowed")));
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 skill.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String finalAvatarValue;

      // Handle Avatar Logic (Placeholder for real upload logic if you have storage set up)
      if (_profileImage != null) {
        // In a real app, upload _profileImage to Supabase Storage here, get URL.
        finalAvatarValue = _selectedAvatarEmoji ?? _animalAvatars[0];
      } else {
        finalAvatarValue = _selectedAvatarEmoji ?? _animalAvatars[_rng.nextInt(_animalAvatars.length)];
      }

      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': _nameController.text.trim(),
        'department': _selectedDept, // Used the variable from Dropdown
        'year_of_study': _selectedYear,
        'bio': _bioController.text.trim(),
        'is_looking_for_team': _isLookingForTeam,
        'avatar_url': finalAvatarValue,
        'skills': _selectedSkills.toList(),
        'github_url': _githubController.text.trim(),
        'linkedin_url': _linkedinController.text.trim(),
        'resume_url': _resumeController.text.trim(),
        'last_active_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticleNetworkPainter(
                    particles: _particles,
                    color: Colors.deepPurple.withOpacity(0.15),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 10,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: Colors.white.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Build Your Profile",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 20),

                          // --- AVATAR SELECTION ---
                          Center(
                            child: GestureDetector(
                              onTap: _showImageOptions,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.deepPurple.shade50,
                                        backgroundImage: imageProvider,
                                        child: _profileImage == null
                                            ? Text(
                                          _selectedAvatarEmoji ?? '?',
                                          style: const TextStyle(fontSize: 45),
                                        )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.deepPurple,
                                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Tap to change",
                                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- BASIC INFO ---
                          _buildTextField(_nameController, "Full Name", Icons.person),
                          const SizedBox(height: 12),

                          // --- DEPARTMENT DROPDOWN (UPDATED) ---
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Department",
                              prefixIcon: Icon(Icons.work, color: Colors.deepPurple.shade300),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50.withOpacity(0.5),
                            ),
                            value: _selectedDept,
                            items: _departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                            onChanged: (val) => setState(() => _selectedDept = val),
                            validator: (val) => val == null ? "Department is required" : null,
                          ),
                          const SizedBox(height: 12),

                          // --- YEAR DROPDOWN ---
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: "Year of Study",
                              prefixIcon: Icon(Icons.school, color: Colors.deepPurple.shade300),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50.withOpacity(0.5),
                            ),
                            value: _selectedYear,
                            items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text("$y Year"))).toList(),
                            onChanged: (val) => setState(() => _selectedYear = val),
                            validator: (val) => val == null ? "Year is required" : null,
                          ),
                          const SizedBox(height: 12),

                          // Bio
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Bio / About Me",
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.info_outline, color: Colors.deepPurple),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50.withOpacity(0.5),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? "Please write a short bio" : null,
                          ),

                          const SizedBox(height: 12),

                          // Looking for Team
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Looking for a team?", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Turn off if you already have a squad"),
                            value: _isLookingForTeam,
                            activeColor: Colors.deepPurple,
                            onChanged: (val) => setState(() => _isLookingForTeam = val),
                          ),

                          const Divider(),
                          const SizedBox(height: 8),

                          // --- SOCIALS ---
                          const Text("Social Links", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildTextField(_githubController, "GitHub URL", Icons.code),
                          const SizedBox(height: 12),
                          _buildTextField(_linkedinController, "LinkedIn URL", Icons.link),
                          const SizedBox(height: 12),
                          _buildTextField(_resumeController, "Resume URL (Optional)", Icons.description, required: false),

                          const SizedBox(height: 24),

                          // --- SKILLS SECTION (Bubbles) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Skills (Max 5)", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _addCustomSkill,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add Custom"),
                              ),
                            ],
                          ),

                          // Skill Selector
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              labelText: "Select Skill to Add",
                              filled: true,
                              fillColor: Colors.grey.shade50.withOpacity(0.5),
                            ),
                            items: _allSkills.map((skill) {
                              return DropdownMenuItem(value: skill, child: Text(skill));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  if (_selectedSkills.length < 5) {
                                    _selectedSkills.add(value);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Max 5 skills allowed")));
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),

                          // Skill Bubbles (Chips)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _selectedSkills.map((skill) {
                                return Chip(
                                  label: Text(skill, style: const TextStyle(color: Colors.deepPurple)),
                                  backgroundColor: Colors.deepPurple.shade50,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: Colors.deepPurple.shade200)
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 18, color: Colors.deepPurple),
                                  onDeleted: () => setState(() => _selectedSkills.remove(skill)),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- SUBMIT ---
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Complete Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50.withOpacity(0.5),
      ),
      validator: required ? (val) => (val == null || val.isEmpty) ? "$label is required" : null : null,
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          children: [
            const Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _optionButton(Icons.photo_library, "Gallery", () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                }),
                _optionButton(Icons.emoji_emotions, "Avatars", () {
                  Navigator.pop(context);
                  _showAvatarPicker();
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _optionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade100,
            child: Icon(icon, color: Colors.deepPurple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label)
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: _animalAvatars.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarEmoji = _animalAvatars[index];
                          _profileImage = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: _selectedAvatarEmoji == _animalAvatars[index]
                              ? Border.all(color: Colors.deepPurple, width: 3)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(_animalAvatars[index], style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  },
                ),
              );
            }
        );
      },
    );
  }
}

// --- BACKGROUND PAINTER CLASSES ---
class ConnectionParticle {
  double x, y, vx, vy;
  ConnectionParticle({required this.x, required this.y, required this.vx, required this.vy});
}

class ParticleNetworkPainter extends CustomPainter {
  final List<ConnectionParticle> particles;
  final Color color;
  ParticleNetworkPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      var p = particles[i];
      p.x += p.vx; p.y += p.vy;
      if (p.x < 0 || p.x > 1) p.vx = -p.vx;
      if (p.y < 0 || p.y > 1) p.vy = -p.vy;

      final offset = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(offset, 4, dotPaint);

      for (var j = i + 1; j < particles.length; j++) {
        var p2 = particles[j];
        double dx = p.x - p2.x, dy = p.y - p2.y;
        if ((dx*dx + dy*dy) < 0.05) {
          paint.color = color.withOpacity((1 - ((dx*dx + dy*dy) / 0.05)) * color.opacity);
          canvas.drawLine(offset, Offset(p2.x * size.width, p2.y * size.height), paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}