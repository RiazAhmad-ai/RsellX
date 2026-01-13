import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/credit_model.dart';
import '../../providers/credit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/services/whatsapp_service.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/pin_dialog.dart';
import 'edit_credit_dialog.dart';
import 'smart_payment_sheet.dart';

class CreditDetailsScreen extends StatelessWidget {
  final CreditRecord record;

  const CreditDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    
    // Safety check for deleted record
    if (!provider.allRecords.contains(record) && !record.isInBox) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (context.mounted) Navigator.pop(context);
       });
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLend = record.type == 'Lend';
    final primaryColor = isLend ? Colors.black : const Color(0xFFD32F2F);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Transaction Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            tooltip: "Edit Record (Secured)",
            onPressed: () => _verifyAndEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Delete Record (Secured)",
            onPressed: () => _verifyAndDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Extra padding for FAB
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0x1A9E9E9E), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isLend ? const Color(0x1A000000) : const Color(0x1AD32F2F),
                    child: Text(record.name[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                  const SizedBox(height: 12),
                  Text(record.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (record.phone.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(record.phone, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            final shopName = context.read<SettingsProvider>().shopName;
                            WhatsAppService.sendCreditReminder(
                              phone: record.phone,
                              name: record.name,
                              balance: record.balance,
                              shopName: shopName,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x1A4CAF50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4D4CAF50)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.send, size: 12, color: Colors.green),
                                SizedBox(width: 4),
                                Text("Reminder", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // Balance
                  Text("Remaining Balance", style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  if (record.isSettled || record.balance <= 0)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                       decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(30)),
                       child: const Text("✔ FULLY SETTLED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                     )
                  else
                     Text("Rs ${Formatter.formatCurrency(record.balance)}", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor)),
                  
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge("Total: Rs ${Formatter.formatCurrency(record.amount)}", Colors.grey[200]!, Colors.black),
                      _badge("Paid: Rs ${Formatter.formatCurrency(record.paidAmount)}", Colors.green[50]!, Colors.green),
                    ],
                  ),
                  
                  if (record.description != null && record.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("NOTE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                           const SizedBox(height: 4),
                           Text(record.description!, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Ledger / History
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0x1A9E9E9E), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Ledger History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Divider(height: 1),
                  
                  if (record.logs.isEmpty)
                     const Padding(
                       padding: EdgeInsets.all(40),
                       child: Center(child: Text("No transactions yet", style: TextStyle(color: Colors.grey))),
                     )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: record.logs.length,
                      itemBuilder: (context, index) {
                         // Show newest first
                         final log = record.logs[record.logs.length - 1 - index];
                         return _buildLogItem(log, index == 0);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentSheet(context),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text("ADD PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLogItem(String log, bool isLatest) {
    String date = "";
    String time = "";
    String detail = log;
    
    // Format: "Paid 500 on 5/1 at 05:30 PM"
    if (log.contains(" on ")) {
       final mainParts = log.split(" on ");
       detail = mainParts[0];
       final dateTimePart = mainParts[1]; // "5/1 at 05:30 PM" OR "5/1"
       
       if (dateTimePart.contains(" at ")) {
         final dtParts = dateTimePart.split(" at ");
         date = dtParts[0];
         time = dtParts[1];
       } else {
         date = dateTimePart;
       }
    }
    
    // Check if it's Edit or Pay
    final isEdit = detail.toLowerCase().contains("edited");
    final icon = isEdit ? Icons.edit_note : Icons.arrow_downward;
    final color = isEdit ? Colors.amber[700]! : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        color: isLatest ? const Color(0x052196F3) : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEdit ? const Color(0x1AFFB000) : const Color(0x1A4CAF50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    if (time.isNotEmpty) ...[
                       const SizedBox(width: 6),
                       Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
                       const SizedBox(width: 3),
                       Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartPaymentSheet(item: record),
    );
  }

  void _verifyAndEdit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        title: "Unlock Editing",
        onSuccess: () {
          // Open Edit Dialog
          showDialog(
            context: context,
            builder: (context) => EditCreditDialog(record: record),
          );
        },
      ),
    );
  }

  void _verifyAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        title: "Confirm Deletion",
        onSuccess: () {
          context.read<CreditProvider>().deleteRecord(record);
          Navigator.pop(context); // Close details screen
        },
      ),
    );
  }
}
