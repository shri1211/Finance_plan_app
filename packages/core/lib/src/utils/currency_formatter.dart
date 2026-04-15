class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹', int decimals = 2}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formatted;
    if (absAmount >= 10000000) {
      formatted = '${(absAmount / 10000000).toStringAsFixed(2)}Cr';
    } else if (absAmount >= 100000) {
      formatted = '${(absAmount / 100000).toStringAsFixed(2)}L';
    } else if (absAmount >= 1000) {
      formatted = '${(absAmount / 1000).toStringAsFixed(2)}K';
    } else {
      formatted = absAmount.toStringAsFixed(decimals);
    }

    return '${isNegative ? '-' : ''}$symbol$formatted';
  }

  static String formatFull(double amount, {String symbol = '₹'}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Indian number format
    String result = '';
    for (int i = 0; i < intPart.length; i++) {
      if (i == intPart.length - 3 && intPart.length > 3) {
        result += ',';
      } else if (i > intPart.length - 3 && (intPart.length - i - 1) % 2 == 1 && i != 0) {
        result += ',';
      }
      result += intPart[i];
    }

    return '${isNegative ? '-' : ''}$symbol$result.$decPart';
  }
}
