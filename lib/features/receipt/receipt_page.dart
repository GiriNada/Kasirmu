import 'dart:io';
import 'dart:ui' as ui;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database_helper.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/receipt_helper.dart';
import '../printer/printer_page.dart';
import 'receipt_settings_page.dart';

class ReceiptPage extends StatefulWidget {
  final int transactionId;
  final int total;
  final int paidAmount;
  final String paymentMethod;
  final String date;

  const ReceiptPage({
    super.key,
    required this.transactionId,
    required this.total,
    required this.paidAmount,
    required this.paymentMethod,
    required this.date,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);
  static const _successGreen = Color(0xFF16A34A);
  static const _dangerRed = Color(0xFFDC2626);

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final PrinterService _printerService = PrinterService.instance;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  final GlobalKey receiptKey = GlobalKey();

  bool printerConnected = false;
  String printerStatus = 'Printer belum terhubung';
  List<Map<String, dynamic>> items = [];
  bool _isLoading = true;
  String _receiptPreview = '';

  int get change => widget.paidAmount - widget.total;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ReceiptHelper.loadStyle(),
      loadItems(),
      checkPrinter(),
    ]);

    if (!mounted) return;
    setState(_updateReceiptPreview);
  }

  void _updateReceiptPreview() {
    _receiptPreview = ReceiptHelper.buildReceiptText(
      transaksiId: widget.transactionId,
      dateTime: DateTime.parse(widget.date),
      method: widget.paymentMethod,
      total: widget.total,
      paid: widget.paidAmount,
      items: items,
      includeStoreName: false,
    );
  }

  Future<void> loadItems() async {
    final data = await DatabaseHelper.instance.getDetailTransaksi(
      widget.transactionId,
    );

    if (!mounted) return;
    setState(() {
      items = data;
      _isLoading = false;
    });
  }

  Future<void> checkPrinter() async {
    final isConnected = await bluetooth.isConnected;

    if (!mounted) return;
    setState(() {
      printerConnected = isConnected ?? false;
      printerStatus =
          printerConnected ? 'Printer terhubung' : 'Printer belum terhubung';
    });
  }

  Future<void> printReceipt() async {
    final printed = await _printerService.printTransactionReceipt(
      transaksiId: widget.transactionId,
      dateTime: DateTime.parse(widget.date),
      method: widget.paymentMethod,
      total: widget.total,
      paid: widget.paidAmount,
      items: items,
    );

    if (!printed) {
      if (!mounted) return;
      setState(() {
        printerStatus = 'Printer belum terhubung';
        printerConnected = false;
      });
      return;
    }
  }

  Future<void> shareReceiptImage() async {
    try {
      final boundary =
          receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/receipt.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parsedDate = DateTime.parse(widget.date);

    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Preview Struk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Struk',
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiptSettingsPage(),
                ),
              );
              if (changed == true && mounted) {
                await ReceiptHelper.loadStyle();
                if (!mounted) return;
                setState(_updateReceiptPreview);
              }
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(parsedDate),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _buildPrinterStatus(),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: receiptKey,
                  child: _buildThermalPreview(_receiptPreview),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bluetooth_searching_rounded),
                      label: const Text('Connect Printer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: const BorderSide(color: _primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrinterPage(),
                          ),
                        );
                        await checkPrinter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            printerConnected ? _successGreen : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: printerConnected ? printReceipt : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: shareReceiptImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text(
                        'Selesai',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime parsedDate) {
    return Container(
      width: double.infinity,
      color: _primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaksi Selesai',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(parsedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rp ${_currencyFormat.format(widget.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterStatus() {
    final color = printerConnected ? _successGreen : _dangerRed;
    final bgColor =
        printerConnected ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              printerConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printerConnected ? 'Printer Siap' : 'Printer Belum Siap',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  printerStatus,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalPreview(String body) {
    final style = ReceiptHelper.currentStyle;

    return Container(
      width: 286,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E0D1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            style.storeName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ReceiptHelper.previewStoreNameFontSize(style: style),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1,
            ),
          ),
          SizedBox(height: 6 + (style.headerSpacing * 4)),
          Text(
            body,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: style.previewLineHeight,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
