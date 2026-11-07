
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../models/incident.dart';
import '../models/incident_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import 'incident_detail_screen.dart';
import 'report_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchText = '';
  String _selectedStatus = 'All';
  bool _uploadingProfilePicture = false;

  final Color purple = const Color(0xFF6842B8);
  final Color darkPurple = const Color(0xFF382064);

  Future<void> _uploadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage == null || !mounted) return;

      setState(() {
        _uploadingProfilePicture = true;
      });

      final imageBytes = await pickedImage.readAsBytes();

      final photoUrl = await CloudinaryService.uploadImage(imageBytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
                   .set({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile picture: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingProfilePicture = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar(String? uid, {double radius = 48}) {
    if (uid == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: purple.withValues(alpha: 0.14),
        child: Icon(
          Icons.person,
          size: radius * 1.15,
          color: purple,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final photoUrl = snapshot.data?.data()?['photoUrl']?.toString();

        return CircleAvatar(
          radius: radius,
          backgroundColor: purple.withValues(alpha: 0.14),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Icon(
                  Icons.person,
                  size: radius * 1.15,
                  color: purple,
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final incidents = incidentProvider.incidents;
    final isStaff = auth.isStaff;

    final currentUser = FirebaseAuth.instance.currentUser;

    final displayName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : (currentUser?.email?.split('@').first ?? 'Student');

    final filteredIncidents = incidents.where((incident) {
      final query = _searchText.toLowerCase();

      final matchesSearch = query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query);

      final matchesStatus = _selectedStatus == 'All' ||
          incident.status.label.toLowerCase() ==
              _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final pages = [
      _buildHomePage(displayName, incidents, incidentProvider.loading),
      _buildReportsPage(filteredIncidents, incidentProvider.loading),
      _buildPrivacyPage(),
      _buildProfilePage(displayName, currentUser?.email ?? 'No email'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => setState(() => _selectedIndex = 3),
            child: _buildProfileAvatar(
              currentUser?.uid,
              radius: 20,
            ),
          ),
        ),
        title: Text(
          _selectedIndex == 0
              ? 'Campus Connect'
              : ['Home', 'Reports', 'Privacy', 'Profile'][_selectedIndex],
          style: const TextStyle(
            color: Color(0xFF241A35),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 1)
            IconButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: Icon(Icons.notifications_none, color: purple),
              tooltip: 'Notifications',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton:
          (_selectedIndex == 0 || _selectedIndex == 1) && !isStaff
              ? FloatingActionButton.extended(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportIncidentScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Report an issue'),
                )
              : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          indicatorColor: purple.withValues(alpha: 0.13),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;

              if (index != 1) {
                _searchText = '';
                _selectedStatus = 'All';
              }
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Privacy',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Modern home dashboard.
  Widget _buildHomePage(
    String displayName,
    List<Incident> incidents,
    bool loading,
  ) {
    final isStaff = context.watch<AuthProvider>().isStaff;

    final total = incidents.length;

    final pending = incidents
        .where((i) => i.status == IncidentStatus.pending)
        .length;

    final inProgress = incidents
        .where((i) => i.status.label.toLowerCase().contains('progress'))
        .length;

    final resolved = incidents
        .where((i) => i.status.label.toLowerCase().contains('resolved'))
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            'Hello, ${displayName.split(' ').first} 👋',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Color(0xFF241A35),
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isStaff
                ? 'Here is what is happening on campus.'
                : 'Together, we can make our campus safer.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF81788F),
            ),
          ),
          const SizedBox(height: 25),

          // Main purple welcome banner.
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF382064),
                  Color(0xFF6842B8),
                  Color(0xFF9069D8),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: purple.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isStaff
                      ? 'Campus safety starts here.'
                      : 'See something? Report it!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isStaff
                      ? 'Your actions help create a safer university community.'
                      : 'Your voice matters. Help us build a safer university community.',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                if (!isStaff) ...[
                  const SizedBox(height: 19),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: darkPurple,
                      minimumSize: const Size(165, 46),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportIncidentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Report an incident'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 29),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Report overview'),
              const Text(
                'Live overview',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8C7BA8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Total reports',
                    total.toString(),
                    Icons.description_outlined,
                    const Color(0xFF6842B8),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _summaryCard(
                    'Pending',
                    pending.toString(),
                    Icons.schedule_rounded,
                    const Color(0xFFE49A28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'In progress',
                    inProgress.toString(),
                    Icons.autorenew_rounded,
                    const Color(0xFF3987C9),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _summaryCard(
                    'Resolved',
                    resolved.toString(),
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF269B70),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 29),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Recent reports'),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 9),

          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (incidents.isEmpty)
            _emptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: 'Incident reports will appear here when available.',
            )
          else
            ...incidents.take(3).map(_incidentTile),
        ],
      ),
    );
  }

  // Reports page with search and status filters.
  Widget _buildReportsPage(List<Incident> incidents, bool loading) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        const Text(
          'Campus reports',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Search and follow the progress of incidents.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search reports...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _searchText = value),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            'All',
            ...IncidentStatus.values.map((s) => s.label),
          ].map(
            (status) {
              return ChoiceChip(
                label: Text(status),
                selected: _selectedStatus == status,
                onSelected: (_) {
                  setState(() => _selectedStatus = status);
                },
                selectedColor: purple.withValues(alpha: 0.18),
              );
            },
          ).toList(),
        ),
        const SizedBox(height: 18),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (incidents.isEmpty)
          _emptyState(
            icon: Icons.search_off,
            title: 'No matching reports',
            message: 'Try another search or status filter.',
          )
        else
          ...incidents.map(_incidentTile),
      ],
    );
  }

  // Privacy information page.
  Widget _buildPrivacyPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6FA),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Icon(
              Icons.shield_moon_outlined,
              size: 85,
              color: Color(0xFF6842B8),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Your privacy matters',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Campus Connect is designed to help students and staff report '
          'incidents responsibly. Your information should only be accessed '
          'by people who need it to manage reports.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        _infoTile(
          Icons.lock_outline,
          'Secure account',
          'Your account is protected by Firebase Authentication.',
        ),
        _infoTile(
          Icons.visibility_outlined,
          'Report access',
          'Reports are available according to your account role and access.',
        ),
        _infoTile(
          Icons.person_off_outlined,
          'Anonymous reporting',
          'Use the anonymous option when submitting a report if it is available.',
        ),
        _infoTile(
          Icons.photo_outlined,
          'Photo privacy',
          'Only upload images that are relevant to the incident.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Please do not include passwords or sensitive personal information '
          'in incident descriptions.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Profile page.
  Widget _buildProfilePage(String displayName, String email) {
    final auth = context.read<AuthProvider>();
    final isStaff = auth.isStaff;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 15),
        Center(
          child: Stack(
            children: [
              _buildProfileAvatar(uid, radius: 48),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: purple,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: Colors.white,
                    onPressed: _uploadingProfilePicture
                        ? null
                        : _uploadProfilePicture,
                    icon: _uploadingProfilePicture
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _uploadingProfilePicture
                ? null
                : _uploadProfilePicture,
            icon: const Icon(Icons.photo_camera),
            label: Text(
              _uploadingProfilePicture
                  ? 'Uploading picture...'
                  : 'Change profile picture',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            displayName,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            email,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Chip(
            avatar: Icon(
              isStaff ? Icons.admin_panel_settings : Icons.school,
              size: 18,
              color: purple,
            ),
            label: Text(
              auth.isAdmin
                  ? 'Administrator'
                  : auth.isResponder
                      ? 'Responder'
                      : 'Student account',
            ),
            backgroundColor: purple.withValues(alpha: 0.10),
          ),
        ),
        const SizedBox(height: 30),
        _infoTile(
          Icons.person_outline,
          'My account',
          'Your account details',
        ),
        _infoTile(
          Icons.shield_outlined,
          'Privacy',
          'Read our privacy information',
        ),
        _infoTile(
          Icons.help_outline,
          'Help and support',
          'Get help using the app',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }

  // Admin assigns an incident to a responder.
  Future<void> _assignIncident(Incident incident) async {
    try {
      final responders = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['responder', 'staff'])
          .get();

      if (!mounted) return;

      if (responders.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No responder accounts are available yet.'),
          ),
        );
        return;
      }

      String? selectedResponder;

      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Assign incident'),
                content: DropdownButtonFormField<String>(
                  initialValue: selectedResponder,
                  decoration: const InputDecoration(
                    labelText: 'Choose a responder',
                    border: OutlineInputBorder(),
                  ),
                  items: responders.docs.map((doc) {
                    final data = doc.data();
                    final name = data['name']?.toString() ?? 'Responder';

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedResponder = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selectedResponder == null
                        ? null
                        : () => Navigator.pop(
                              dialogContext,
                              selectedResponder,
                            ),
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected == null || !mounted) return;

      await context.read<IncidentProvider>().assignIncident(
            incidentId: incident.id,
            responderUid: selected,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident assigned successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not assign incident: $e'),
        ),
      );
    }
  }

  // Responder updates the status of an assigned incident.
  Future<void> _updateIncidentStatus(Incident incident) async {
    IncidentStatus selectedStatus = incident.status;

    try {
      final result = await showDialog<IncidentStatus>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Update incident'),
                content: DropdownButtonFormField<IncidentStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Incident status',
                    border: OutlineInputBorder(),
                  ),
                  items: IncidentStatus.values.map((status) {
                    return DropdownMenuItem<IncidentStatus>(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, selectedStatus);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !mounted) return;

      await context.read<IncidentProvider>().updateStatus(
            incident.id,
            result,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident status updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update incident: $e'),
        ),
      );
    }
  }

  // Incident card with role-specific actions.
  Widget _incidentTile(Incident incident) {
    final auth = context.read<AuthProvider>();

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEFE9F8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(11),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: incident.photoUrl != null && incident.photoUrl!.isNotEmpty
              ? Image.network(
                  incident.photoUrl!,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _photoPlaceholder(),
                )
              : _photoPlaceholder(),
        ),
        title: Text(
          incident.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                incident.status.label,
                style: const TextStyle(
                  color: Color(0xFF6842B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.isAdmin)
              IconButton(
                tooltip: 'Assign responder',
                icon: const Icon(Icons.person_add_alt_1),
                color: purple,
                onPressed: () => _assignIncident(incident),
              ),
            if (auth.isResponder)
              IconButton(
                tooltip: 'Update status',
                icon: const Icon(Icons.edit_note),
                color: purple,
                onPressed: () => _updateIncidentStatus(incident),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidentDetailScreen(
                incidentId: incident.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFFEDE6FA),
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF6842B8),
        size: 27,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF241A35),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEFE9F8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 45, color: purple),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFEFE9F8)),
      ),
      child: ListTile(
        leading: Icon(icon, color: purple, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  // Modern statistics card.
  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEFE9F8),
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF81788F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
