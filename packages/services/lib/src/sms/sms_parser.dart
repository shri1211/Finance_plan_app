import 'package:domain/domain.dart';
import 'package:uuid/uuid.dart';

/// Parsed result from an SMS message
class SmsParseResult {
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String title;
  final String? merchant;
  final DateTime date;
  final String rawSms;

  const SmsParseResult({
    required this.amount,
    required this.type,
    required this.category,
    required this.title,
    this.merchant,
    required this.date,
    required this.rawSms,
  });

  Transaction toTransaction() {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      category: category,
      title: title,
      merchant: merchant,
      date: date,
      isSmsParsed: true,
      isSynced: false,
      rawSms: rawSms,
    );
  }
}

/// Indian SMS Parser — supports UPI, bank debit/credit, wallets
class SmsParser {
  // Amount patterns (INR formats)
  static final _amountPatterns = [
    RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)', caseSensitive: false),
    RegExp(r'amount\s*(?:of|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
  ];

  // Debit keywords
  static final _debitKeywords = RegExp(
    r'\b(debited|debit|spent|paid|payment|withdrawn|purchase|pos|'
    r'autopay|emi|transferred to|sent to|UPI-DR|dr\.?)\b',
    caseSensitive: false,
  );

  // Credit keywords
  static final _creditKeywords = RegExp(
    r'\b(credited|credit|received|cashback|refund|reversal|transferred from|'
    r'sent by|UPI-CR|cr\.?|salary|deposited)\b',
    caseSensitive: false,
  );

  // Merchant patterns
  static final _merchantPatterns = [
    RegExp(r"(?:at|to|from|merchant:)\s+([A-Z][A-Za-z0-9 &\-\'\.]{2,30})",
        caseSensitive: false),
    RegExp(r'UPI-(?:DR|CR)/[^/]+/([^/]+)/', caseSensitive: false),
  ];

  // Date patterns
  static final _datePatterns = [
    RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4})'),
    RegExp(r'(\d{2}[-/]\d{2}[-/]\d{2})'),
    RegExp(r'(\d{4}[-/]\d{2}[-/]\d{2})'),
    RegExp(r'(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*\d{2,4})',
        caseSensitive: false),
  ];

  // Bank sender identifiers
  static final _bankSenders = {
    'HDFCBK': 'HDFC Bank',
    'ICICIBK': 'ICICI Bank',
    'SBICRD': 'SBI',
    'AXISBK': 'Axis Bank',
    'KOTAKB': 'Kotak Bank',
    'PAYTM': 'Paytm',
    'GPAY': 'Google Pay',
    'PHONEPE': 'PhonePe',
    'YESBNK': 'Yes Bank',
    'INDUSB': 'IndusInd Bank',
    'PNBSMS': 'PNB',
    'CANBNK': 'Canara Bank',
  };

  /// Parse an SMS message. Returns null if it cannot be parsed as a financial SMS.
  static SmsParseResult? parse(String sms, {DateTime? receivedAt}) {
    if (!_isFinancialSms(sms)) return null;

    final amount = _extractAmount(sms);
    if (amount == null || amount <= 0) return null;

    final type = _extractType(sms);
    final merchant = _extractMerchant(sms);
    final date = _extractDate(sms) ?? receivedAt ?? DateTime.now();
    final category = _guessCategory(sms, merchant);
    final title = _buildTitle(type, merchant, amount);

    return SmsParseResult(
      amount: amount,
      type: type,
      category: category,
      title: title,
      merchant: merchant,
      date: date,
      rawSms: sms,
    );
  }

  static bool _isFinancialSms(String sms) {
    final lower = sms.toLowerCase();
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('inr') ||
        lower.contains('rs.') ||
        lower.contains('₹') ||
        lower.contains('upi') ||
        lower.contains('payment') ||
        lower.contains('transaction');
  }

  static double? _extractAmount(String sms) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }

  static TransactionType _extractType(String sms) {
    if (_creditKeywords.hasMatch(sms)) return TransactionType.credit;
    if (_debitKeywords.hasMatch(sms)) return TransactionType.debit;
    // Default to debit for ambiguous SMS
    return TransactionType.debit;
  }

  static String? _extractMerchant(String sms) {
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  static DateTime? _extractDate(String sms) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        return _parseDate(match.group(1)!);
      }
    }
    return null;
  }

  static DateTime? _parseDate(String raw) {
    try {
      // Try DD-MM-YYYY or DD/MM/YYYY
      final parts = raw.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        if (parts[2].length == 4) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          final year = int.parse(parts[2]) + 2000;
          return DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  static TransactionCategory _guessCategory(String sms, String? merchant) {
    final lower = sms.toLowerCase();
    final m = merchant?.toLowerCase() ?? '';

    if (_matchesAny(lower + m, ['swiggy', 'zomato', 'restaurant', 'hotel', 'food', 'dominos', 'pizza', 'cafe'])) {
      return TransactionCategory.food;
    }
    if (_matchesAny(lower + m, ['uber', 'ola', 'rapido', 'metro', 'irctc', 'bus', 'fuel', 'petrol', 'diesel'])) {
      return TransactionCategory.transport;
    }
    if (_matchesAny(lower + m, ['amazon', 'flipkart', 'myntra', 'shopping', 'mall', 'store', 'retail'])) {
      return TransactionCategory.shopping;
    }
    if (_matchesAny(lower + m, ['netflix', 'hotstar', 'spotify', 'prime', 'movie', 'cinema', 'pvr', 'inox'])) {
      return TransactionCategory.entertainment;
    }
    if (_matchesAny(lower + m, ['hospital', 'pharmacy', 'medical', 'clinic', 'doctor', 'health', 'apollo', 'medplus'])) {
      return TransactionCategory.health;
    }
    if (_matchesAny(lower + m, ['electricity', 'water', 'gas', 'broadband', 'wifi', 'airtel', 'jio', 'bsnl', 'utility', 'bill'])) {
      return TransactionCategory.utilities;
    }
    if (_matchesAny(lower + m, ['school', 'college', 'university', 'education', 'tuition', 'fee', 'course'])) {
      return TransactionCategory.education;
    }
    if (_matchesAny(lower + m, ['salary', 'payroll', 'wages', 'income'])) {
      return TransactionCategory.salary;
    }
    if (_matchesAny(lower + m, ['mutual fund', 'sip', 'stock', 'invest', 'zerodha', 'groww', 'kuvera', 'nps'])) {
      return TransactionCategory.investment;
    }
    if (_matchesAny(lower + m, ['transfer', 'upi', 'neft', 'imps', 'rtgs'])) {
      return TransactionCategory.transfer;
    }
    return TransactionCategory.other;
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  static String _buildTitle(TransactionType type, String? merchant, double amount) {
    if (merchant != null) {
      return type == TransactionType.debit
          ? 'Payment to $merchant'
          : 'Received from $merchant';
    }
    return type == TransactionType.debit
        ? 'Debit ₹${amount.toStringAsFixed(0)}'
        : 'Credit ₹${amount.toStringAsFixed(0)}';
  }

  /// Parse multiple SMS messages, filtering invalid ones
  static List<SmsParseResult> parseAll(List<String> messages, {DateTime? receivedAt}) {
    final results = <SmsParseResult>[];
    for (final sms in messages) {
      final result = parse(sms, receivedAt: receivedAt);
      if (result != null) results.add(result);
    }
    return results;
  }
}
