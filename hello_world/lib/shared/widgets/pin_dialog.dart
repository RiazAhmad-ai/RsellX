import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/settings_provider.dart';

class PinDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final String title;
  
  const PinDialog({super.key, required this.onSuccess, this.title = "Security Check"});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pinController = TextEditingController();
  String _error = "";
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  Widget build(BuildContext context) {
    // Get Admin PIN from Settings (Default: 1234)
    final correctPin = context.read<SettingsProvider>().adminPasscode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_person, size: 32, color: Colors.blueAccent),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Enter Admin PIN to continue", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            // PIN Input
            Container(
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _pinController,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  hintText: "****",
                ),
                onChanged: (val) {
                  if (val.length == 4) {
                    if (val == correctPin) {
                      Navigator.pop(context);
                      widget.onSuccess();
                    } else {
                      setState(() {
                        _attempts++;
                        if (_attempts >= _maxAttempts) {
                          _error = "Too many failed attempts. Try again later.";
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) Navigator.pop(context);
                          });
                        } else {
                          _error = "Incorrect PIN. ${_maxAttempts - _attempts} attempts left.";
                        }
                        _pinController.clear();
                      });
                    }
                  }
                },
              ),
            ),
            
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}
