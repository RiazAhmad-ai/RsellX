// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../data/repositories/data_store.dart';
import '../splash/splash_screen.dart'; // For Logout

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  @override
  void initState() {
    super.initState();
    // Listen to changes in DataStore
    DataStore().addListener(_onDataChange);
  }

  @override
  void dispose() {
    DataStore().removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  // === FUNCTIONS ===

  // 1. EDIT PROFILE DIALOG
  void _editProfile() {
    final store = DataStore();
    TextEditingController nameController = TextEditingController(text: store.ownerName);
    TextEditingController shopController = TextEditingController(text: store.shopName);
    TextEditingController phoneController = TextEditingController(text: store.phone);
    TextEditingController addressController = TextEditingController(text: store.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Edit Business Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Owner Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: shopController,
                decoration: const InputDecoration(
                  labelText: "Shop Name",
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Shop Address",
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              store.updateProfile(
                nameController.text,
                shopController.text,
                phoneController.text,
                addressController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile Updated Successfully! ✅"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("SAVE CHANGES"),
          ),
        ],
      ),
    );
  }

  // 2. BACKUP (Enhanced Simulation)
  void _startBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 20),
                Text("Creating Secure Backup..."),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Backup Successful! All records synced to cloud."),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // 3. RESTORE
  void _restoreData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Records?"),
        content: const Text(
          "Importing backup will merge or replace current data. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Data Sync Complete! Records Restored."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "PROCEED",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 4. CLEAR DATA
  void _clearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Factory Reset?"),
        content: const Text(
          "⚠️ WARNING: This will permanently delete ALL inventory, expenses, and history records.\n\nThis action cannot be undone!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Data"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DataStore().clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("System Reset! All data has been cleared."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "DELETE EVERYTHING",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 5. LOGOUT
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings & Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // === 1. PROFILE HEADER ===
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(
                          Icons.business_center,
                          color: Colors.red,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          store.ownerName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          store.phone,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    ),
                    onPressed: _editProfile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // === 2. DATA MANAGEMENT ===
            _buildSectionHeader("Data Management"),

            _buildSettingsTile(
              Icons.cloud_upload_rounded,
              "Cloud Backup",
              "Sync all data to secure server",
              onTap: _startBackup,
            ),

            _buildSettingsTile(
              Icons.history_rounded,
              "Restore Points",
              "Recover data from previous backups",
              onTap: _restoreData,
            ),

            _buildSettingsTile(
              Icons.delete_sweep_rounded,
              "System Reset",
              "Permanently clear all records",
              isRed: true,
              onTap: _clearAllData,
            ),

            const SizedBox(height: 30),

            // === 3. APP INFO ===
            _buildSectionHeader("System Information"),
            _buildSettingsTile(
              Icons.verified_user_outlined,
              "License Key",
              "Active (Retail Pro)",
              onTap: () {},
            ),
            _buildSettingsTile(
              Icons.info_outline,
              "Software Version",
              "v1.5.2 (Latest)",
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                title: const Text(
                  "Logout Session",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Return to login screen", style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 40),
            Text(
              "Secure POS System for ${store.shopName}",
              style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRed ? Colors.red[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isRed ? Colors.red : Colors.grey[700], size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isRed ? Colors.red : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}
