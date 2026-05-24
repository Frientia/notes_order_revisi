import 'package:intl/intl.dart';

class AppFormatters {
  static String rupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    
    double amount = number is String ? double.tryParse(number) ?? 0 : number.toDouble();
    
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String angka(dynamic number) {
    if (number == null) return '0';
    
    double amount = number is String ? double.tryParse(number) ?? 0 : number.toDouble();
    
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount).trim();
  }

  static String tanggal(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String waktu(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}