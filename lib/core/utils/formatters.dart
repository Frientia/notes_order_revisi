import 'package:intl/intl.dart';

class AppFormatters {
  /// Mengubah angka menjadi format Rupiah lengkap (Contoh: Rp 1.500.000)
  static String rupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    
    // Pastikan nilai dikonversi ke double untuk formatting
    double amount = number is String ? double.tryParse(number) ?? 0 : number.toDouble();
    
    return NumberFormat.currency(
      locale: 'id_ID', // Format Indonesia
      symbol: 'Rp ',
      decimalDigits: 0, // 0 agar tidak ada koma di belakang (misal: ,00)
    ).format(amount);
  }

  /// Mengubah angka menjadi pemisah ribuan tanpa simbol Rp (Contoh: 1.500.000)
  static String angka(dynamic number) {
    if (number == null) return '0';
    
    double amount = number is String ? double.tryParse(number) ?? 0 : number.toDouble();
    
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount).trim();
  }

  /// Format tanggal standar Indonesia (Contoh: 24 Mei 2026)
  static String tanggal(DateTime? date) {
    if (date == null) return '-';
    // Gunakan pola dd MMM yyyy atau dd/MM/yyyy tergantung preferensi
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format tanggal dan waktu (Contoh: 24/05/2026 14:30)
  static String waktu(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}