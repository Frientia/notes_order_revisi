import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../data/models/riwayat_model.dart';
import 'formatters.dart';

class ReportGenerator {
  
  // --- GENERATOR PDF ---
  static Future<void> generatePDF(String judulPeriode, List<PencatatanModel> data) async {
    final pdf = pw.Document();
    
    double grandTotalSemua = 0;
    List<List<String>> tableData = [];
    int no = 1;

    // Proses 'Flattening' Data (Mengurai 1 Nota yang berisi banyak barang menjadi baris-baris berurutan)
    for (var nota in data) {
      grandTotalSemua += nota.totalHarga;
      
      if (nota.details.isEmpty) continue; // Lewati nota kosong

      for (var i = 0; i < nota.details.length; i++) {
        var detail = nota.details[i];
        tableData.add([
          (i == 0) ? no.toString() : '', // Nomor hanya di baris pertama tiap nota
          (i == 0) ? AppFormatters.waktu(nota.tglPencatatan) : '',
          (i == 0) ? '#${nota.idPencatatan}' : '',
          detail.namaBarang,
          detail.noPlatMobil,
          detail.namaToko,
          detail.qty.toString(),
          AppFormatters.rupiah(detail.hargaPembelian),
          AppFormatters.rupiah(detail.subtotal),
        ]);
      }
      no++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Diubah ke Landscape agar 9 Kolom muat
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER INFORMASI
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('LAPORAN RINCIAN TRANSAKSI LOGISTIK', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Periode: $judulPeriode', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.Text('Dicetak pada: ${AppFormatters.waktu(DateTime.now())}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // ISI TABEL TRANSAKSI (9 Kolom)
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Tanggal', 'ID Nota', 'Barang', 'Alokasi Mobil', 'Toko Tujuan', 'Qty', 'Harga (Rp)', 'Subtotal (Rp)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
              data: tableData,
            ),
            pw.SizedBox(height: 20),

            // FOOTER / KESIMPULAN
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Grand Total Pengeluaran: ${AppFormatters.rupiah(grandTotalSemua)}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Laporan_Rincian_Transaksi_$judulPeriode.pdf',
    );
  }

  // --- GENERATOR EXCEL ---
  static Future<void> generateExcel(String judulPeriode, List<PencatatanModel> data) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan Transaksi'];
    excel.setDefaultSheet('Laporan Transaksi');

    // Buat Header (9 Kolom)
    sheetObject.appendRow([
      TextCellValue('No'),
      TextCellValue('Tanggal'),
      TextCellValue('ID Transaksi'),
      TextCellValue('Nama Barang'),
      TextCellValue('Alokasi Mobil'),
      TextCellValue('Toko Tujuan'),
      TextCellValue('Qty'),
      TextCellValue('Harga Satuan (Rp)'),
      TextCellValue('Subtotal (Rp)')
    ]);

    // Isi Data dan Hitung Kesimpulan
    double grandTotalSemua = 0;
    int no = 1;

    for (var nota in data) {
      grandTotalSemua += nota.totalHarga;
      
      for (var i = 0; i < nota.details.length; i++) {
        var detail = nota.details[i];
        sheetObject.appendRow([
          (i == 0) ? IntCellValue(no) : TextCellValue(''), 
          (i == 0) ? TextCellValue(AppFormatters.waktu(nota.tglPencatatan)) : TextCellValue(''),
          (i == 0) ? TextCellValue('#${nota.idPencatatan}') : TextCellValue(''),
          TextCellValue(detail.namaBarang),
          TextCellValue(detail.noPlatMobil),
          TextCellValue(detail.namaToko),
          IntCellValue(detail.qty),
          DoubleCellValue(detail.hargaPembelian),
          DoubleCellValue(detail.subtotal),
        ]);
      }
      no++;
    }

    // Baris Kosong & Footer Grand Total
    sheetObject.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('')]);
    sheetObject.appendRow([
      TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue(''),
      TextCellValue('GRAND TOTAL:'),
      DoubleCellValue(grandTotalSemua)
    ]);

    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      final xFile = XFile.fromData(
        Uint8List.fromList(fileBytes),
        name: 'Laporan_Rincian_Transaksi_$judulPeriode.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      
      await Share.shareXFiles(
        [xFile], 
        text: 'Laporan Excel Transaksi $judulPeriode'
      );
    }
  }
}