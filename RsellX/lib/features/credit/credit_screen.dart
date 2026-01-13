import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/credit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/models/credit_model.dart';
import '../../shared/utils/formatting.dart';
import 'credit_details_screen.dart';
import '../../core/utils/debouncer.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = "";
  final _searchDebouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditProvider = context.watch<CreditProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isVisible = settingsProvider.isBalanceVisible;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Khata Book", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // === TOTALS DASHBOARD ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildSmartCard("To Receive", creditProvider.totalToReceive, Colors.black, Icons.arrow_downward, isVisible)),
                const SizedBox(width: 12),
                Expanded(child: _buildSmartCard("To Pay", creditProvider.totalToPay, const Color(0xFFD32F2F), Icons.arrow_upward, isVisible)),
              ],
            ),
          ),
          
          // === SMART SEARCH BAR ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                _searchDebouncer.run(() {
                  if (mounted) {
                    setState(() => _searchQuery = val.toLowerCase());
                  }
                });
              },
              decoration: InputDecoration(
                hintText: "Search Name, Phone, or Amount...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ""); }, icon: const Icon(Icons.clear, size: 20)) 
                  : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          
          // === TABS ===
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: Colors.blueAccent, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0x4D448AFF), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: "Receive (Diya)"),
                Tab(text: "Pay (Liya)"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // === LISTS ===
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CreditList(type: 'Lend', query: _searchQuery, isVisible: isVisible), 
                CreditList(type: 'Borrow', query: _searchQuery, isVisible: isVisible), 
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.blueAccent, 
        icon: const Icon(Icons.add),
        label: const Text("New Entry"),
        elevation: 4,
      ),
    );
  }

  Widget _buildSmartCard(String title, double amount, Color color, IconData icon, bool isVisible) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(color.red, color.green, color.blue, 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVisible ? "Rs ${Formatter.formatCurrency(amount)}" : "Rs •••••••", 
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddCreditDialog());
  }
}

class CreditList extends StatelessWidget {
  final String type; 
  final String query;
  final bool isVisible;
  const CreditList({super.key, required this.type, required this.query, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    final allRecords = type == 'Lend' ? provider.receivables : provider.payables;
    
    // Filter
    final records = allRecords.where((item) {
       if (query.isEmpty) return true;
       return item.name.toLowerCase().contains(query) || 
              item.phone.contains(query) || 
              item.amount.toInt().toString().contains(query);
    }).toList();

    final isLend = type == 'Lend';
    
    // Theme Colors: Black for Receive, Red for Pay
    final themeColor = isLend ? Colors.black : const Color(0xFFD32F2F);

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text("No records found", style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final item = records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D9E9E9E),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isLend ? const Color(0x14000000) : const Color(0x14D32F2F),
              child: Text(
                item.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                   const SizedBox(height: 6),
                   Wrap(
                     spacing: 8,
                     crossAxisAlignment: WrapCrossAlignment.center,
                     children: [
                       Text("Total: ${item.amount.toInt()}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                       Container(width: 1, height: 10, color: Colors.grey[300]),
                       Text("Paid: ${isVisible ? item.paidAmount.toInt() : '••••'}", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                       Container(width: 1, height: 10, color: Colors.grey[300]),
                       Text("Start: ${DateFormat('d/M/yy').format(item.date)}", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                       
                       if (item.isSettled) ...[
                         Container(width: 1, height: 10, color: Colors.grey[300]),
                         Builder(
                           builder: (context) {
                             String closedDate = "Unknown";
                             if (item.logs.isNotEmpty) {
                               final lastLog = item.logs.last;
                               if (lastLog.contains(" on ")) {
                                  closedDate = lastLog.split(" on ")[1].split(" at ")[0];
                               }
                             }
                             return Text("End: $closedDate", style: TextStyle(fontSize: 10, color: Colors.red[300], fontWeight: FontWeight.bold));
                           }
                         ),
                       ]
                     ],
                   ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.isSettled || item.balance <= 0)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(8)),
                     child: const Text("✔ CLOSED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                   )
                else ...[
                  Text(
                    isVisible ? "Rs ${item.balance.toStringAsFixed(0)}" : "Rs ••••",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  Text("REMAINING", style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CreditDetailsScreen(record: item)),
              );
            },
            onLongPress: () => _confirmDelete(context, item),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CreditRecord item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<CreditProvider>().deleteRecord(item);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddCreditDialog extends StatefulWidget {
  const AddCreditDialog({super.key});

  @override
  State<AddCreditDialog> createState() => _AddCreditDialogState();
}

class _AddCreditDialogState extends State<AddCreditDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'Lend'; 

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blue header for New Entry
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          children: [
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Text("New Khata Entry", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _buildTypeBtn("Receive (Black)", 'Lend', Colors.black)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTypeBtn("Pay (Red)", 'Borrow', const Color(0xFFD32F2F))),
                  ]),
                  const SizedBox(height: 20),
                  TextField(controller: _nameCtrl, decoration: _inputDec("Name", Icons.person)),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _inputDec("Phone", Icons.phone)),
                  const SizedBox(height: 12),
                  TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: _inputDec("Amount", Icons.attach_money)),
                  const SizedBox(height: 12),
                  TextField(controller: _descCtrl, decoration: _inputDec("Description", Icons.notes)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, 
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTypeBtn(String label, String value, Color color) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    context.read<CreditProvider>().addCredit(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      type: _type,
      description: _descCtrl.text,
    );
    Navigator.pop(context);
  }
}
