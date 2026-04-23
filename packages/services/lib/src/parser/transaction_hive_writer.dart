import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// A lightweight, dependency-injection-free Hive writer.
/// Safe to use inside background isolates (SMS background handler)
/// where GetIt and typed adapters are unavailable.
///
/// Writes to a *staging* box [autoCaptureStagingBox] as plain Maps.
/// The [AutoCaptureProcessor] in the mobile_app layer
/// reads this box on resume and converts it into real TransactionModel objects.
class TransactionHiveWriter {
  static const autoCaptureStagingBox = 'auto_captured_transactions';

  static Future<void> writeTransaction({
    required double amount,
    required int type,      // TransactionType.index
    required int category,  // TransactionCategory.index
    required String title,
    String? merchant,
    String? description,
    required DateTime date,
  }) async {
    try {
      if (!Hive.isBoxOpen(autoCaptureStagingBox)) {
        await Hive.openBox(autoCaptureStagingBox);
      }

      final box = Hive.box(autoCaptureStagingBox);
      final id = const Uuid().v4();

      await box.put(id, {
        'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'title': title,
        'merchant': merchant,
        'description': description ?? 'Auto-captured from SMS/Notification',
        'date': date.toIso8601String(),
        'isSynced': false,
        'isSmsParsed': true,
      });

      print('[AutoCapture] Staged: $title | ₹$amount');
    } catch (e) {
      print('[AutoCapture] Stage write failed: $e');
    }
  }
}
