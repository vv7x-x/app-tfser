import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String? reportId;
  const ConfirmationScreen({super.key, this.reportId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأكيد البلاغ'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text('تم إرسال البلاغ بنجاح!', style: TextStyle(fontSize: 18)),
                if (reportId != null) ...[
                  const SizedBox(height: 8),
                  Text('رقم البلاغ: $reportId'),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}