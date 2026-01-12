import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/credit_model.dart';
import '../../providers/credit_provider.dart';
import '../../shared/utils/formatting.dart';

class SmartPaymentSheet extends StatefulWidget {
  final CreditRecord item;

  const SmartPaymentSheet({super.key, required this.item});

  @override
  State<SmartPaymentSheet> createState() => _SmartPaymentSheetState();
}

class _SmartPaymentSheetState extends State<SmartPaymentSheet> {
  final _amountCtrl = TextEditingController();
  bool _isRemoveMode = false; // Toggle state: false = Add/Receive, true = Remove/Refund

  @override
  Widget build(BuildContext context) {
    // Theme colors based on mode
    final themeColor = _isRemoveMode ? Colors.red : Colors.blueAccent;
    final actionText = _isRemoveMode ? "REFUND / REMOVE" : "ADD PAYMENT";

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            
            // TOGGLE SWITCH (ADD / REMOVE)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                   Expanded(child: _buildToggleBtn("Add Payment (+)", false, Colors.blueAccent)),
                   Expanded(child: _buildToggleBtn("Remove (-)", true, Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // BALANCE CARD
            Center(
              child: Column(
                children: [
                  Text("Remaining Balance", style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text("Rs ${Formatter.formatCurrency(widget.item.balance)}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // INPUT FIELD
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor),
              decoration: InputDecoration(
                hintText: "Enter Amount",
                fillColor: _isRemoveMode ? const Color(0x0DFF0000) : const Color(0x0D448AFF),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                prefixIcon: _isRemoveMode 
                  ? const Icon(Icons.remove, color: Colors.red) 
                  : const Icon(Icons.add, color: Colors.blueAccent),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // QUICK CHIPS (100, 500, 1000, Full)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChip(100),
                  const SizedBox(width: 8),
                  _buildChip(500),
                  const SizedBox(width: 8),
                  _buildChip(1000),
                  const SizedBox(width: 8),
                  // "Full" button
                  GestureDetector(
                    onTap: () => _amountCtrl.text = widget.item.balance.toInt().toString(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                      child: const Text("Full", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ACTION BUTTON
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(_amountCtrl.text) ?? 0;
                  if (amt > 0) {
                    // Logic: If Remove Mode, pass negative amount
                    final finalAmt = _isRemoveMode ? -amt : amt;
                    context.read<CreditProvider>().addPayment(widget.item, finalAmt);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: Text(actionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
             const SizedBox(height: 24),
             
             // === HISTORY SECTION ===
            if (widget.item.logs.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "TRANSACTION HISTORY", 
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.item.logs.length,
                  itemBuilder: (context, index) {
                    // Reverse order logs
                    final log = widget.item.logs[widget.item.logs.length - 1 - index]; 
                    return _buildHistoryItem(log);
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isRemove, Color color) {
    final isSelected = _isRemoveMode == isRemove;
    return GestureDetector(
      onTap: () => setState(() {
         _isRemoveMode = isRemove;
         _amountCtrl.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: Colors.transparent),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600], 
              fontWeight: FontWeight.bold,
              fontSize: 13
            )
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String log) {
    // Basic Parsing (Robust)
    String amount = "";
    String date = "";
    String time = "";
    String type = "Paid"; // Default
    
    // Check type keywords
    if (log.contains("Refunded")) type = "Refunded";
    else if (log.contains("Edited")) type = "Edited";
    
    // Clean log string to "500 on 5/1 at 12:00"
    final cleanLog = log.replaceAll("Paid ", "").replaceAll("Refunded ", "").replaceAll("Edited Record ", "").trim();
    
    if (cleanLog.contains(" on ")) {
       try {
         final parts = cleanLog.split(" on ");
         // If Edit, usually no amount in current implementation, but robust check:
         if (type == "Edited") {
            amount = "-";
            date = parts[1]; 
         } else {
            amount = parts[0];
            date = parts[1];
         }
         
         if (date.contains(" at ")) {
            final dt = date.split(" at ");
            date = dt[0];
            time = dt[1];
         }
       } catch (e) {
         amount = "?";
       }
    } else {
       amount = cleanLog;
    }

    final isRefund = type == "Refunded";
    final isEdit = type == "Edited";
    
    // UI Styling
    final color = isRefund ? Colors.red : (isEdit ? Colors.amber[700]! : Colors.green);
    final icon = isRefund ? Icons.remove_circle_outline : (isEdit ? Icons.edit_note : Icons.check_circle_outline);
    final prefix = isRefund ? "- " : (isEdit ? "" : "+ ");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
           Container(
             decoration: BoxDecoration(
               color: isRefund ? const Color(0x1AFF0000) : (isEdit ? const Color(0x1AFFB000) : const Color(0x1A4CAF50)),
               shape: BoxShape.circle,
             ),
             padding: const EdgeInsets.all(8),
             child: Icon(icon, size: 16, color: color),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(type == "Paid" ? "Payment Received" : type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 2),
                 Row(
                   children: [
                      Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text("• $time", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ]
                   ],
                 )
               ],
             ),
           ),
           if (!isEdit)
           Text(
             "$prefix Rs $amount",
             style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
           ),
        ],
      ),
    );
  }

  Widget _buildChip(int amount) {
    return GestureDetector(
      onTap: () {
        final current = double.tryParse(_amountCtrl.text) ?? 0;
        _amountCtrl.text = (current + amount).toInt().toString(); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text("+ $amount", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
      ),
    );
  }
}
