import 'package:telephony/telephony.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../sms/sms_parser.dart';
import 'transaction_hive_writer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level function required by telephony for background SMS processing.
// Must be top-level (not inside a class) and annotated with vm:entry-point.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> onBackgroundSmsReceived(SmsMessage message) async {
  await Hive.initFlutter();
  await _parseAndSave(message.body ?? '', message.date);
}

Future<void> _parseAndSave(String text, int? timestamp) async {
  final DateTime receivedAt = timestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
      : DateTime.now();

  final result = SmsParser.parse(text, receivedAt: receivedAt);
  if (result == null) return;

  await TransactionHiveWriter.writeTransaction(
    amount: result.amount,
    type: result.type.index,
    category: result.category.index,
    title: result.title,
    merchant: result.merchant,
    description: 'Auto-captured from SMS',
    date: result.date,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// UPI app package names to listen to for notifications
// ─────────────────────────────────────────────────────────────────────────────
const _upiPackages = {
  'com.google.android.apps.nbu.paisa.user', // Google Pay
  'com.phonepe.app',                          // PhonePe
  'net.one97.paytm',                          // Paytm
  'com.dreamplug.androidapp',                 // CRED
  'in.amazon.mShop.android.shopping',         // Amazon Pay
  'com.mobikwik_new',                         // MobiKwik
};

// ─────────────────────────────────────────────────────────────────────────────
// BackgroundParserService — Core orchestrator
// ─────────────────────────────────────────────────────────────────────────────
class BackgroundParserService {
  static final Telephony _telephony = Telephony.instance;
  static bool _initialized = false;
  static bool _isListeningSms = false;
  static bool _isListeningNotifications = false;

  /// Setup internal state. Call this once in main.dart.
  /// Does NOT request permissions or start listeners.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    print('[AutoCapture] BackgroundParserService initialized.');
  }

  /// Checks permissions and starts listeners if granted.
  /// If [forceRequest] is true, it will show permission dialogs.
  /// This should be called after login.
  static Future<void> ensureListening({bool forceRequest = false}) async {
    await _initSmsListener(forceRequest: forceRequest);
    await _initNotificationListener(forceRequest: forceRequest);
  }

  // ── SMS Listener ────────────────────────────────────────────────────────────
  static Future<void> _initSmsListener({bool forceRequest = false}) async {
    if (_isListeningSms) return;
    try {
      bool? granted;
      if (forceRequest) {
        granted = await _telephony.requestPhoneAndSmsPermissions;
      } else {
        // Telephony doesn't have a direct 'checkPermission' without requesting, 
        // but calling requestPhoneAndSmsPermissions usually returns immediately if already granted.
        // However, to keep it 'silent', we might just try to check if it's already granted via another way 
        // or just let it be for now since telephony's request is what we have.
        // For now, if not force, we just return to avoid popping dialogs in HomeShell initState.
        return;
      }

      if (granted != true) {
        print('[AutoCapture] SMS permission not granted.');
        return;
      }

      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          print('[AutoCapture] Foreground SMS received from: ${message.address}');
          await _parseAndSave(message.body ?? '', message.date);
        },
        onBackgroundMessage: onBackgroundSmsReceived,
      );

      _isListeningSms = true;
      print('[AutoCapture] SMS listener active.');
    } catch (e) {
      print('[AutoCapture] SMS init error: $e');
    }
  }

  // ── Notification Listener ───────────────────────────────────────────────────
  static Future<void> _initNotificationListener({bool forceRequest = false}) async {
    if (_isListeningNotifications) return;
    try {
      final bool granted = await NotificationListenerService.isPermissionGranted();
      if (!granted) {
        if (forceRequest) {
          await NotificationListenerService.requestPermission();
          // We don't wait for result here as requestPermission opens settings
        }
        print('[AutoCapture] Notification access not granted.');
        return;
      }

      NotificationListenerService.notificationsStream.listen(
        (ServiceNotificationEvent event) async {
          // Filter only UPI apps and bank apps
          if (event.packageName == null) return;
          
          // Check UPI apps first
          final bool isUpiApp = _upiPackages.contains(event.packageName);
          
          // For bank SMSes that come as notifications (some banks do this)
          final bool isBankApp = event.packageName!.contains('bank') ||
              event.packageName!.contains('hdfc') ||
              event.packageName!.contains('icici') ||
              event.packageName!.contains('sbi') ||
              event.packageName!.contains('axis');

          if (!isUpiApp && !isBankApp) return;

          final String combined =
              '${event.title ?? ""} ${event.content ?? ""}';

          print('[AutoCapture] Notification from ${event.packageName}: $combined');

          // Run through the Core Brain
          final result = SmsParser.parse(combined, receivedAt: DateTime.now());
          if (result == null) return;

          await TransactionHiveWriter.writeTransaction(
            amount: result.amount,
            type: result.type.index,
            category: result.category.index,
            title: result.title,
            merchant: result.merchant,
            description: 'Auto-captured from ${event.packageName}',
            date: result.date,
          );
        },
        onError: (e) => print('[AutoCapture] Notification stream error: $e'),
      );

      _isListeningNotifications = true;
      print('[AutoCapture] Notification listener active.');
    } catch (e) {
      print('[AutoCapture] Notification init error: $e');
    }
  }

  /// Check if Notification Listener permission is granted
  static Future<bool> hasNotificationPermission() =>
      NotificationListenerService.isPermissionGranted();

  /// Open Android Notification Listener settings so user can grant access
  static Future<void> requestNotificationPermission() =>
      NotificationListenerService.requestPermission();

  /// Check if SMS/Phone permissions are granted
  static Future<bool> hasSmsPermission() async {
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }
}
