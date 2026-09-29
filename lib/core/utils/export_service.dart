import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class ExportService {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  static Future<void> exportTransaksiCSV() async {
    final data = await DatabaseHelper.instance.getAllTransaksi();

    if (data.isEmpty) return;

    String csv = 'ID,Tanggal,Total,Bayar,Metode\n';

    for (final t in data) {
      csv +=
          '${t['id']},${t['created_at']},${t['total']},${t['paid_amount']},${t['payment_method']}\n';
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/backup_transaksi_kasir.csv');

    await file.writeAsString(csv);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Backup data transaksi kasir');
  }

  static Future<File?> exportReportXlsx({
    required String periodLabel,
    required String periodType,
    required int totalPenjualan,
    required int totalTransaksi,
    required List<Map<String, dynamic>> transaksi,
    required List<Map<String, dynamic>> menuTerjual,
    required List<Map<String, dynamic>> menuTidakLaku,
  }) async {
    final excel = Excel.createExcel();
    final transaksiSheet = excel['Transaksi'];
    final ringkasanSheet = excel['Ringkasan'];

    excel.delete('Sheet1');

    _buildRingkasanSheet(
      ringkasanSheet,
      periodLabel: periodLabel,
      periodType: periodType,
      totalPenjualan: totalPenjualan,
      totalTransaksi: totalTransaksi,
      menuTerjual: menuTerjual,
      menuTidakLaku: menuTidakLaku,
    );
    _buildTransaksiSheet(
      transaksiSheet,
      transaksi,
      periodLabel: periodLabel,
      totalPenjualan: totalPenjualan,
      totalTransaksi: totalTransaksi,
    );

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final safePeriod =
        periodLabel.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').replaceAll(' ', '_');
    final file = File('${dir.path}/laporan_${periodType}_$safePeriod.xlsx');

    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan penjualan $periodLabel',
    );

    return file;
  }

  static void _buildRingkasanSheet(
    Sheet sheet, {
    required String periodLabel,
    required String periodType,
    required int totalPenjualan,
    required int totalTransaksi,
    required List<Map<String, dynamic>> menuTerjual,
    required List<Map<String, dynamic>> menuTidakLaku,
  }) {
    sheet.appendRow([TextCellValue('Ringkasan Laporan')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('Periode'), TextCellValue(periodLabel)]);
    sheet.appendRow([TextCellValue('Jenis Laporan'), TextCellValue(periodType)]);
    sheet.appendRow([
      TextCellValue('Total Penjualan'),
      TextCellValue('Rp ${_currencyFormat.format(totalPenjualan)}'),
    ]);
    sheet.appendRow([
      TextCellValue('Total Transaksi'),
      IntCellValue(totalTransaksi),
    ]);
    sheet.appendRow([
      TextCellValue('Menu Terlaris'),
      TextCellValue(
        menuTerjual.isEmpty
            ? '-'
            : '${menuTerjual.first['name']} (${menuTerjual.first['total_qty']}x)',
      ),
    ]);
    sheet.appendRow([
      TextCellValue('Menu Tidak Laku'),
      TextCellValue(
        menuTidakLaku.isEmpty ? '-' : menuTidakLaku.map((e) => e['name']).join(', '),
      ),
    ]);
  }

  static void _buildTransaksiSheet(
    Sheet sheet,
    List<Map<String, dynamic>> transaksi, {
    required String periodLabel,
    required int totalPenjualan,
    required int totalTransaksi,
  }) {
    sheet.appendRow([TextCellValue('Laporan Transaksi')]);
    sheet.appendRow([TextCellValue('Periode'), TextCellValue(periodLabel)]);
    sheet.appendRow([
      TextCellValue('Total Transaksi'),
      IntCellValue(totalTransaksi),
    ]);
    sheet.appendRow([
      TextCellValue('Total Penjualan'),
      TextCellValue('Rp ${_currencyFormat.format(totalPenjualan)}'),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('ID Transaksi'),
      TextCellValue('Tanggal'),
      TextCellValue('Jam'),
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Total'),
      TextCellValue('Dibayar'),
      TextCellValue('Kembalian'),
    ]);

    for (final trx in transaksi) {
      final dateTime = _parseDate(trx['created_at']?.toString());
      final total = (trx['total'] ?? 0) as int;
      final paid = (trx['paid_amount'] ?? 0) as int;
      final change = paid - total;

      sheet.appendRow([
        IntCellValue((trx['id'] ?? 0) as int),
        TextCellValue(
          dateTime == null ? '-' : DateFormat('dd MMM yyyy').format(dateTime),
        ),
        TextCellValue(
          dateTime == null ? '-' : DateFormat('HH:mm').format(dateTime),
        ),
        TextCellValue((trx['payment_method'] ?? '-').toString()),
        IntCellValue(total),
        IntCellValue(paid),
        IntCellValue(change < 0 ? 0 : change),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Rp ${_currencyFormat.format(totalPenjualan)}'),
      TextCellValue(''),
      TextCellValue(''),
    ]);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
