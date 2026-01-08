// lib/features/settings/settings_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import 'package:rsellx/providers/backup_provider.dart';
import '../splash/splash_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/reporting_service.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // === PROTECTIVE PASSCODE DIALOG ===
  Future<bool> _verifyPasscode() async {
    final settingsProvider = context.read<SettingsProvider>();
    String enteredPasscode = "";
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.accent),
            const SizedBox(width: 10),
            Text("Admin Access", style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enter your admin passcode to proceed with this sensitive action.",
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: const InputDecoration(
                hintText: "••••",
                counterText: "",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => enteredPasscode = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (enteredPasscode == settingsProvider.adminPasscode) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Incorrect Passcode! ❌"),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // === FUNCTIONS ===

  // 1. EDIT PROFILE DIALOG
  void _editProfile() {
    final settingsProvider = context.read<SettingsProvider>();
    TextEditingController nameController = TextEditingController(text: settingsProvider.ownerName);
    TextEditingController shopController = TextEditingController(text: settingsProvider.shopName);
    TextEditingController phoneController = TextEditingController(text: settingsProvider.phone);
    TextEditingController addressController = TextEditingController(text: settingsProvider.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Edit Business Profile",
          style: AppTextStyles.h3,
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
              settingsProvider.updateProfile(
                nameController.text,
                shopController.text,
                phoneController.text,
                addressController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile Updated Successfully! ✅"),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: const Text("SAVE CHANGES"),
          ),
        ],
      ),
    );
  }

  // 1b. CHANGE PASSCODE DIALOG
  void _changePasscode() async {
    if (!await _verifyPasscode()) return;
    final settingsProvider = context.read<SettingsProvider>();
    String newPasscode = "";
    String confirmPasscode = "";

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Admin Passcode", style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: "New 4-Digit Passcode"),
              onChanged: (val) => newPasscode = val,
            ),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: "Confirm New Passcode"),
              onChanged: (val) => confirmPasscode = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (newPasscode.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passcode must be 4 digits!")));
                return;
              }
              if (newPasscode != confirmPasscode) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passcodes do not match!")));
                return;
              }
              settingsProvider.updatePasscode(newPasscode);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Passcode changed successfully! ✅"), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("CHANGE"),
          ),
        ],
      ),
    );
  }


  // 2. BACKUP using BackupService
  void _startBackup() async {
    if (!await _verifyPasscode()) return;
    try {
      await context.read<BackupProvider>().exportBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup generated and shared! 💾"), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Backup Failed: $e")));
    }
  }

  // 3. IMPORT using BackupService
  void _importBackup() async {
    if (!await _verifyPasscode()) return;
    try {
       final success = await context.read<BackupProvider>().importBackup();
       if (success && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Data Restored Successfully! ✅"), backgroundColor: AppColors.success),
         );
       }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Restore Failed: $e")));
    }
  }

  // 3b. EXCEL IMPORT
  void _importFromExcel() async {
    if (!await _verifyPasscode()) return;
    try {
      final success = await context.read<BackupProvider>().importInventoryFromExcel();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory Imported from Excel! ✅"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Excel Import Failed: $e")));
    }
  }

  // 4. CLEAR DATA (With Passcode)
  void _clearAllData() async {
    if (!await _verifyPasscode()) return;

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
              await context.read<BackupProvider>().clearAllData();
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final settingsProvider = context.read<SettingsProvider>();

      // Permanent Directoy main save karna
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'shop_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final File logoFile = File('${directory.path}/$fileName');
      
      // Copy the image
      await File(image.path).copy(logoFile.path);

      await settingsProvider.updateProfile(
        settingsProvider.ownerName,
        settingsProvider.shopName,
        settingsProvider.phone,
        settingsProvider.address,
        logo: logoFile.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop logo updated successfully! ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Format error or selection cancelled: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings & Profile",
          style: AppTextStyles.h2,
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
                    child: settingsProvider.logoPath != null && File(settingsProvider.logoPath!).existsSync()
                      ? Image.file(
                          File(settingsProvider.logoPath!),
                          fit: BoxFit.cover,
                          key: ValueKey(settingsProvider.logoPath),
                        )
                      : Image.asset(
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
                          settingsProvider.shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          settingsProvider.ownerName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          settingsProvider.phone,
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

            // === 2. UI & APPEARANCE ===
            _buildSectionHeader("Appearance & Graphics"),
            _buildSettingsTile(
              Icons.image_outlined,
              "Change Shop Logo",
              settingsProvider.logoPath != null ? "Custom logo is set" : "Using default logo",
              onTap: _pickLogo,
              trailing: settingsProvider.logoPath != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(settingsProvider.logoPath!), 
                      width: 30, 
                      height: 30, 
                      fit: BoxFit.cover,
                      key: ValueKey(settingsProvider.logoPath), // Cache bust key
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            ),
            _buildSettingsTile(
              Icons.lock_reset_rounded,
              "Change Admin Passcode",
              "Update security PIN for sensitive actions",
              onTap: _changePasscode,
            ),

            const SizedBox(height: 10),

            // === 3. DATA MANAGEMENT ===
            _buildSectionHeader("Data Management"),

            _buildSettingsTile(
              Icons.save_alt_rounded,
              "Export Local Backup",
              "Save all data to a file",
              onTap: _startBackup,
            ),

            _buildSettingsTile(
              Icons.upload_file_rounded,
              "Import Data",
              "Restore from backup file",
              onTap: _importBackup,
            ),

            _buildSettingsTile(
              Icons.table_rows_rounded,
              "Import Inventory (Excel)",
              "Bulk add items from .xlsx",
              onTap: _importFromExcel,
            ),


            _buildSettingsTile(
              Icons.delete_sweep_rounded,
              "System Reset",
              "Permanently clear all records",
              isRed: true,
              onTap: _clearAllData,
            ),

            const SizedBox(height: 30),

            const SizedBox(height: 10),



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
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  "Logout Session",
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Return to login screen", style: AppTextStyles.label),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 40),
            const SizedBox(height: 10),
            Text(
              "Secure POS System for ${settingsProvider.shopName}",
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
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
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
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade100 : Colors.transparent),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRed ? AppColors.error.withOpacity(0.1) : (Theme.of(context).brightness == Brightness.light ? AppColors.background : Colors.white10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isRed ? AppColors.error : AppColors.textSecondary, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isRed ? AppColors.error : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.label,
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}
