import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'history_screen.dart';
import 'expense_screen.dart';
import 'camera_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // === CHANGE 1: List mein Order badal diya ===
  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Home
    const InventoryScreen(), // 1: Stock
    const ExpenseScreen(), // 2: Kharcha (Pehle yeh Index 3 tha)
    const HistoryScreen(), // 3: History (Ab yeh last mein hai)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen(mode: 'sell')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      // Floating Camera Button
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: _openCamera,
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // === CHANGE 2: Buttons ki jagah badal di ===
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left Side (Same rahega)
              _buildTabItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: "Home",
                index: 0,
              ),
              _buildTabItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: "Stock",
                index: 1,
              ),

              // Beech mein Camera ke liye gap
              const SizedBox(width: 48),

              // Right Side (YAHAN SWAP HUA HAI)
              // Pehle Kharcha (Index 2)
              _buildTabItem(
                icon: Icons.wallet_outlined,
                activeIcon: Icons.wallet,
                label: "Kharcha",
                index: 2,
              ),
              // Phir History (Index 3)
              _buildTabItem(
                icon: Icons.history,
                activeIcon: Icons.history,
                label: "History",
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.red : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.red : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
