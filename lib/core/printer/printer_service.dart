import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/receipt_helper.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._internal();

  factory PrinterService() {
    return instance;
  }

  PrinterService._internal();

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? connectedDevice;

  /// GET LIST PRINTER
  Future<List<BluetoothDevice>> getDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint('Failed to get bonded devices: $e');
    }
    return devices;
  }

  /// CONNECT PRINTER
  Future<bool> connect(BluetoothDevice device) async {
    try {
      bool? isConnected = await bluetooth.isConnected;

      /// disconnect dulu kalau sudah connect
      if (isConnected == true) {
        await bluetooth.disconnect();
      }

      await bluetooth.connect(device);

      connectedDevice = device;

      /// simpan printer terakhir
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_printer", device.address ?? "");

      return true;
    } catch (e) {
      debugPrint('Failed to connect printer: $e');
      return false;
    }
  }

  /// CEK CONNECT
  Future<bool> isConnected() async {
    bool? connected = await bluetooth.isConnected;
    return connected ?? false;
  }

  /// AUTO RECONNECT PRINTER
  Future<bool> autoReconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? lastPrinter = prefs.getString("last_printer");

      if (lastPrinter == null) return false;

      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      BluetoothDevice? device;

      for (var d in devices) {
        if (d.address == lastPrinter) {
          device = d;
          break;
        }
      }

      if (device == null) return false;

      await bluetooth.connect(device);

      connectedDevice = device;

      return true;
    } catch (e) {
      debugPrint('Failed to auto reconnect printer: $e');
      return false;
    }
  }

  /// TEST PRINT
  Future<void> printTest() async {
    bool connected = await isConnected();

    if (!connected) return;

    bluetooth.printNewLine();
    bluetooth.printCustom("KASIRMU", 3, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Printer siap digunakan", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Test print berhasil", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }

  Future<bool> printTransactionReceipt({
    required int transaksiId,
    required DateTime dateTime,
    required String method,
    required int total,
    required int paid,
    required List<Map<String, dynamic>> items,
  }) async {
    final connected = await isConnected();
    if (!connected) return false;

    await ReceiptHelper.loadStyle();
    final style = ReceiptHelper.currentStyle;
    final formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);
    final change = paid - total;

    bluetooth.printNewLine();
    bluetooth.printCustom(
      style.storeName.toUpperCase(),
      style.storeNamePrintSize,
      1,
    );
    _printBlankLines(style.headerSpacing);

    for (final line in style.headerLines) {
      _printLine(line, size: 0, align: 1);
    }

    if (style.headerLines.isNotEmpty && style.storeAddressLines.isNotEmpty) {
      bluetooth.printNewLine();
    }

    for (final line in style.storeAddressLines) {
      _printLine(line, size: 0, align: 1);
    }

    _printBlankLines(style.sectionSpacing);
    _printLine(ReceiptHelper.line(style: style));
    _printBlankLines(style.sectionSpacing);
    _printLine(ReceiptHelper.formatLine('Tanggal', formattedDate, style: style));
    _printLine(ReceiptHelper.formatLine('Jam', formattedTime, style: style));
    _printLine(ReceiptHelper.formatLine('Metode', method, style: style));

    _printBlankLines(style.sectionSpacing);
    _printLine(ReceiptHelper.line(style: style));
    _printBlankLines(style.sectionSpacing);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final qty = (item['qty'] ?? 0) as int;
      final price = (item['price'] ?? 0) as int;
      _printLine(item['name'].toString());
      _printLine(
        ReceiptHelper.formatLine(
          '$qty x ${ReceiptHelper.formatRupiah(price).replaceAll('Rp ', '')}',
          ReceiptHelper.formatRupiah(qty * price).replaceAll('Rp ', ''),
          style: style,
        ),
      );

      if (i < items.length - 1) {
        _printBlankLines(style.itemSpacing);
      }
    }

    _printBlankLines(style.sectionSpacing);
    _printLine(ReceiptHelper.line(style: style));
    _printBlankLines(style.sectionSpacing);
    _printLine(
      ReceiptHelper.formatLine(
        'TOTAL',
        ReceiptHelper.formatRupiah(total).replaceAll('Rp ', ''),
        style: style,
      ),
      size: 1,
    );
    _printLine(
      ReceiptHelper.formatLine(
        'BAYAR',
        ReceiptHelper.formatRupiah(paid).replaceAll('Rp ', ''),
        style: style,
      ),
    );
    _printLine(
      ReceiptHelper.formatLine(
        'KEMBALI',
        ReceiptHelper.formatRupiah(change < 0 ? 0 : change).replaceAll('Rp ', ''),
        style: style,
      ),
    );

    _printBlankLines(style.sectionSpacing);
    _printLine(ReceiptHelper.line(style: style));
    _printBlankLines(style.sectionSpacing);

    for (final line in style.footerLines) {
      _printLine(line, size: 0, align: 1);
    }

    bluetooth.printNewLine();
    bluetooth.printNewLine();

    return true;
  }

  void _printLine(
    String text, {
    int size = 0,
    int align = 0,
  }) {
    bluetooth.printCustom(text, size, align);
  }

  void _printBlankLines(int count) {
    for (var i = 0; i < count; i++) {
      bluetooth.printNewLine();
    }
  }
}
