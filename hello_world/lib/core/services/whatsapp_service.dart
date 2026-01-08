import 'package:url_launcher/url_launcher.dart';
import '../services/logger_service.dart';

class WhatsAppService {
  static Future<void> sendCreditReminder({
    required String phone,
    required String name,
    required double balance,
    required String shopName,
    bool inUrdu = true,
  }) async {
    // Clean phone number (remove spaces, dashes)
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '92${cleanPhone.substring(1)}'; // Default to Pakistan if starts with 0
      } else if (!cleanPhone.startsWith('92')) {
        cleanPhone = '92$cleanPhone';
      }
    }

    final String message = inUrdu
        ? "Assalam-o-Alaikum $name,\n\n$shopName se reminder hai ke aap ka baqi balance Rs. ${balance.toInt()} hai. Meharbani ker ke jald settlement ker lain. Shukriya!"
        : "Hi $name,\n\nReminder from $shopName. Your outstanding balance is Rs. ${balance.toInt()}. Please settle it at your earliest convenience. Thank you!";

    final Uri whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.error("Could not launch WhatsApp for $cleanPhone");
      }
    } catch (e) {
      AppLogger.error("WhatsApp launch error", error: e);
    }
  }
}
