import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services/services.dart';

void main() {
  group('SmsParser.parse', () {
    test('parses debit UPI SMS with amount, merchant, category and date', () {
      const sms =
          'INR 1,250.50 debited from A/c XX1234 to SWIGGY on 20/04/2026 via UPI Ref 91234.';

      final result = SmsParser.parse(sms);

      expect(result, isNotNull);
      expect(result!.amount, 1250.50);
      expect(result.type, TransactionType.debit);
      expect(result.merchant?.toLowerCase(), contains('swiggy'));
      expect(result.category, TransactionCategory.food);
      expect(result.date, DateTime(2026, 4, 20));
      expect(result.title, startsWith('Payment to'));
    });

    test('parses credit salary SMS and classifies as salary', () {
      const sms =
          'Salary of INR 50000 credited to your account on 01-04-2026.';

      final result = SmsParser.parse(sms);

      expect(result, isNotNull);
      expect(result!.amount, 50000);
      expect(result.type, TransactionType.credit);
      expect(result.category, TransactionCategory.salary);
      expect(result.date, DateTime(2026, 4, 1));
    });

    test('uses receivedAt when no date is present in SMS', () {
      final receivedAt = DateTime(2026, 4, 20, 9, 30, 0);
      const sms = 'Rs. 299 debited for UPI payment to Uber.';

      final result = SmsParser.parse(sms, receivedAt: receivedAt);

      expect(result, isNotNull);
      expect(result!.date, receivedAt);
      expect(result.category, TransactionCategory.transport);
    });

    test('returns null for non-financial SMS', () {
      const sms = 'Your OTP for login is 482911. Do not share it.';

      final result = SmsParser.parse(sms);

      expect(result, isNull);
    });
  });

  group('SmsParser.parseAll', () {
    test('returns only valid financial messages', () {
      final results = SmsParser.parseAll([
        'INR 450 debited at Zomato on 18/04/2026.',
        'Your OTP is 123456.',
        'INR 1000 credited to account on 19/04/2026.',
      ]);

      expect(results.length, 2);
      expect(results[0].type, TransactionType.debit);
      expect(results[1].type, TransactionType.credit);
    });
  });

  group('SmsParseResult.toTransaction', () {
    test('creates SMS parsed unsynced transaction', () {
      const sms = 'INR 999 debited to AMAZON on 15/04/2026.';
      final result = SmsParser.parse(sms);

      expect(result, isNotNull);
      final tx = result!.toTransaction();

      expect(tx.id, isNotEmpty);
      expect(tx.amount, 999);
      expect(tx.isSmsParsed, isTrue);
      expect(tx.isSynced, isFalse);
      expect(tx.rawSms, sms);
    });
  });
}
