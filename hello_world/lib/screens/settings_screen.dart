// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Logout ke liye

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. STATE VARIABLES (Jo change ho sakte hain)
  String ownerName = "Riaz Ahmad";
  String shopName = "Riaz Ahmad Crokery";
  String phone = "+92 3195910091";

  // === FUNCTIONS (Features ko Zinda karne ke liye) ===

  // 1. EDIT PROFILE DIALOG
  void _editProfile() {
    TextEditingController nameController = TextEditingController(
      text: ownerName,
    );
    TextEditingController shopController = TextEditingController(
      text: shopName,
    );
    TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
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
                labelText: "Phone",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                ownerName = nameController.text;
                shopName = shopController.text;
                phone = phoneController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile Updated!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  // 2. BACKUP SIMULATION
  void _startBackup() async {
    // Loading dikhao
    showDialog(
      context: context,
      barrierDismissible: false, // User side par click karke band na kar sake
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 20),
                Text("Backing up Data..."),
              ],
            ),
          ),
        ),
      ),
    );

    // 2 Second ka intezar (Fake Processing)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // Loading band
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Backup Successful! Saved to Cloud."),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // 3. RESTORE SIMULATION
  void _restoreData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Data?"),
        content: const Text(
          "Pichla backup wapis layen? Current data replace ho jayega.",
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
                  content: Text("Data Restored Successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "RESTORE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 4. CLEAR DATA (Danger Zone)
  void _clearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset App?"),
        content: const Text(
          "⚠️ SARA DATA DELETE HO JAYEGA!\nKya aap sure hain?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Asli app mein yahan database delete code aayega
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All Data Cleared! App is new."),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              "DELETE ALL",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 5. LOGOUT
  void _logout() {
    // Splash screen par wapis bhej do (Restart)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // === 1. PROFILE HEADER (Editable) ===
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      errorBuilder: (c, o, s) => const Icon(
                        Icons.storefront,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Info (Using Variables)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ownerName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: _editProfile, // <--- Function Call
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // General Section DELETED ✅

            // === 2. DATA MANAGEMENT (Features Alive) ===
            _buildSectionHeader("Data Management"),

            _buildSettingsTile(
              Icons.cloud_upload,
              "Backup Data",
              "Save to secure cloud",
              onTap: _startBackup, // <--- Function Call
            ),

            _buildSettingsTile(
              Icons.restore,
              "Restore Data",
              "Import from backup",
              onTap: _restoreData, // <--- Function Call
            ),

            _buildSettingsTile(
              Icons.delete_forever,
              "Clear All Data",
              "Factory Reset",
              isRed: true,
              onTap: _clearAllData, // <--- Function Call
            ),

            const SizedBox(height: 20),

            // === 3. APP INFO ===
            _buildSectionHeader("About"),
            _buildSettingsTile(
              Icons.info_outline,
              "App Version",
              "v1.0.0 (Pro)",
              onTap: () {},
            ),

            // Logout Button
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Sign out from device",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: _logout, // <--- Restart App
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Bismillah Store System",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helpers
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
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
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1), // Divider Effect
      child: ListTile(
        leading: Icon(icon, color: isRed ? Colors.red : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: isRed ? Colors.red : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
