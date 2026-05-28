import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:notes_order/domain/providers/riwayat_provider_boss.dart';
import 'package:notes_order/core/utils/formatters.dart';

class ExportService {
  static List<List<RiwayatTransaksi>> _groupDataByNota(
    List<RiwayatTransaksi> data,
  ) {
    Map<int, List<RiwayatTransaksi>> mapGroup = {};
    for (var item in data) {
      if (!mapGroup.containsKey(item.idNota)) {
        mapGroup[item.idNota] = [];
      }
      mapGroup[item.idNota]!.add(item);
    }
    return mapGroup.values.toList();
  }

  // =================== 1. GENERATE PDF (FORMAT GROUPING NOTA) ===================
  static Future<String> cetakPdf({
    required List<RiwayatTransaksi> data,
    required String periode,
  }) async {
    final pdf = pw.Document();
    final formatTanggal = DateFormat('dd/MM/yyyy HH:mm');
    final ByteData logoBytes = await rootBundle.load(
      'assets/logo/logolahirbaru.png',
    );
    final Uint8List logoUint8List = logoBytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoUint8List);

    final double totalPengeluaran = data.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final groupedTransactions = _groupDataByNota(data);
    int totalLunas = 0;
    int totalHutang = 0;

    for (var group in groupedTransactions) {
      if (group.first.status == 'SELESAI' || group.first.status == 'LUNAS') {
        totalLunas++;
      } else {
        totalHutang++;
      }
    }
    List<List<String>> tableData = [];
    int nomorUrut = 1;

    for (var group in groupedTransactions) {
      for (int i = 0; i < group.length; i++) {
        final item = group[i];
        if (i == 0) {
          tableData.add([
            '$nomorUrut',
            formatTanggal.format(item.tanggal),
            '#${item.idNota}',
            item.namaBarang,
            item.nopolMobil,
            item.namaToko,
            '${item.qty}',
            AppFormatters.rupiah(item.harga),
            AppFormatters.rupiah(item.subtotal),
          ]);
        } else {
          tableData.add([
            '',
            '',
            '',
            item.namaBarang,
            item.nopolMobil,
            item.namaToko,
            '${item.qty}',
            AppFormatters.rupiah(item.harga),
            AppFormatters.rupiah(item.subtotal),
          ]);
        }
      }
      nomorUrut++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 40,
          marginTop: 40,
          marginLeft: 30,
          marginRight: 30,
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // --- 2. MASUKKAN LOGO DI SEBELAH NAMA PERUSAHAAN ---
                pw.Row(
                  children: [
                    pw.Image(
                      logoImage,
                      width: 45,
                      height: 45,
                    ), // Atur ukuran logo di sini
                    pw.SizedBox(width: 12), // Jarak antara logo dan teks
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PT LAHIR BARUTAMA',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.Text(
                          'Laporan Logistik & Pengadaan Sparepart Armada',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  child: pw.Text(
                    'LAPORAN RESMI',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2, color: PdfColors.blueGrey900),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dicetak sistem pada: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            'PERIODE LAPORAN: $periode',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfKpiItem(
                  'Total Transaksi',
                  '${groupedTransactions.length} Nota',
                ),
                _pdfKpiItem('Lunas/Selesai', '$totalLunas Nota'),
                _pdfKpiItem('Hutang Pending', '$totalHutang Nota'),
                _pdfKpiItem(
                  'Grand Total',
                  AppFormatters.rupiah(totalPengeluaran),
                  color: PdfColors.red700,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // TABEL PDF
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Tanggal',
              'ID Nota',
              'Nama Barang',
              'No Plat',
              'Toko',
              'Qty',
              'Harga Satuan',
              'Subtotal',
            ],
            data: tableData, // Data yang sudah di-group dimasukkan ke sini
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 40),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Tangerang, ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 50),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Pimpinan Executive',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final Uint8List fileBytes = await pdf.save();
    final tglFile = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final namaFile = 'Laporan_Biaya_Armada_$tglFile.pdf';

    await Printing.sharePdf(bytes: fileBytes, filename: namaFile);
    return namaFile;
  }

  static pw.Widget _pdfKpiItem(String title, String val, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          val,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  // =================== 2. GENERATE EXCEL (FORMAT GROUPING NOTA) ===================
  static Future<void> eksporExcel({
    required List<RiwayatTransaksi> data,
    required String periode,
  }) async {
    var excel = ex.Excel.createExcel();
    var sheet = excel['Laporan Pengeluaran'];
    excel.delete('Sheet1');

    ex.CellStyle headerStyle = ex.CellStyle(
      bold: true,
      fontColorHex: ex.ExcelColor.white,
      backgroundColorHex: ex.ExcelColor.blueGrey800,
      horizontalAlign: ex.HorizontalAlign.Center,
    );

    sheet.appendRow([
      ex.TextCellValue('LAPORAN REKAPITULASI BIAYA SPAREPART & ARMADA'),
    ]);
    sheet.appendRow([ex.TextCellValue('PT LAHIR BARUTAMA')]);
    sheet.appendRow([ex.TextCellValue('Periode Penarikan: $periode')]);
    sheet.appendRow([]);

    // Header sesuai dengan gambar (9 Kolom)
    List<String> headers = [
      'No',
      'Tanggal Transaksi',
      'ID Nota',
      'Nama Barang',
      'No Plat Mobil',
      'Toko',
      'Qty',
      'Harga Satuan',
      'Subtotal',
    ];
    sheet.appendRow(headers.map((e) => ex.TextCellValue(e)).toList());

    for (int col = 0; col < headers.length; col++) {
      var cell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4),
      );
      cell.cellStyle = headerStyle;
    }

    // Kelompokkan data agar rapi
    final groupedTransactions = _groupDataByNota(data);

    int startRowIndex = 6;
    int currentRow = startRowIndex;
    int nomorUrut = 1;

    for (var group in groupedTransactions) {
      for (int i = 0; i < group.length; i++) {
        final item = group[i];
        if (i == 0) {
          // Baris PERTAMA dari Nota
          sheet.appendRow([
            ex.IntCellValue(nomorUrut),
            ex.TextCellValue(
              DateFormat('dd/MM/yyyy HH:mm').format(item.tanggal),
            ),
            ex.TextCellValue('#${item.idNota}'),
            ex.TextCellValue(item.namaBarang),
            ex.TextCellValue(item.nopolMobil),
            ex.TextCellValue(item.namaToko),
            ex.IntCellValue(item.qty),
            ex.DoubleCellValue(item.harga),
            ex.DoubleCellValue(item.subtotal),
          ]);
        } else {
          // Baris SELANJUTNYA dari Nota yang sama (Kolom 1,2,3 dikosongi)
          sheet.appendRow([
            ex.TextCellValue(''),
            ex.TextCellValue(''),
            ex.TextCellValue(''),
            ex.TextCellValue(item.namaBarang),
            ex.TextCellValue(item.nopolMobil),
            ex.TextCellValue(item.namaToko),
            ex.IntCellValue(item.qty),
            ex.DoubleCellValue(item.harga),
            ex.DoubleCellValue(item.subtotal),
          ]);
        }
        currentRow++;
      }
      nomorUrut++;
    }

    // 4. PASANG RUMUS OTOMATIS EXCEL UNTUK GRAND TOTAL
    int lastDataRow = currentRow - 1;
    int totalRowIndex = currentRow;

    List<ex.CellValue?> totalRow = List.generate(headers.length, (_) => null);
    totalRow[7] = ex.TextCellValue('GRAND TOTAL BIAYA:');

    // Karena Subtotal ada di kolom terakhir (ke-9 / Index 8), yaitu Kolom "I" di Excel
    String formulaSum = "SUM(I$startRowIndex:I$lastDataRow)";
    totalRow[8] = ex.FormulaCellValue(formulaSum);
    sheet.appendRow(totalRow);

    var totalLabelCell = sheet.cell(
      ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: totalRowIndex),
    );
    var totalFormulaCell = sheet.cell(
      ex.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRowIndex),
    );
    ex.CellStyle boldStyle = ex.CellStyle(
      bold: true,
      backgroundColorHex: ex.ExcelColor.grey200,
    );
    totalLabelCell.cellStyle = boldStyle;
    totalFormulaCell.cellStyle = boldStyle;

    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      final tglFile = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final namaFile = 'Laporan_Biaya_Armada_$tglFile.xlsx';

      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(fileBytes),
            name: namaFile,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text:
            'Halo Boss, berikut lampiran berkas Excel rekapitulasi biaya pengeluaran armada.',
      );
    }
  }
}
