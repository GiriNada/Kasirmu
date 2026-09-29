import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/database_helper.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/receipt_helper.dart';
import '../printer/printer_page.dart';

class TransactionDetailPage extends StatefulWidget {
  final int transaksiId;
  final int total;

  const TransactionDetailPage({
    super.key,
    required this.transaksiId,
    required this.total,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _surfaceTint = Color(0xFFF1F5F9);
  static const _successGreen = Color(0xFF16A34A);

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  final PrinterService _printerService = PrinterService.instance;

  List<Map<String, dynamic>> items = [];
  Map<String, dynamic>? transaksi;
  bool _isLoading = true;
  String _receiptText = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ReceiptHelper.loadStyle(),
      loadDetail(),
    ]);

    if (!mounted || transaksi == null) return;
    final trx = transaksi!;
    setState(() {
      _receiptText = ReceiptHelper.buildReceiptText(
        transaksiId: widget.transaksiId,
        dateTime: DateTime.parse(trx['created_at'].toString()),
        method: (trx['payment_method'] ?? '-').toString(),
        total: (trx['total'] ?? 0) as int,
        paid: (trx['paid_amount'] ?? 0) as int,
        items: items,
        includeStoreName: false,
      );
    });
  }

  Future<void> loadDetail() async {
    final results = await Future.wait<dynamic>([
      DatabaseHelper.instance.getDetailTransaksi(widget.transaksiId),
      DatabaseHelper.instance.getTransaksiById(widget.transaksiId),
    ]);

    final detail = List<Map<String, dynamic>>.from(results[0] as List);
    final trx = results[1] as Map<String, dynamic>?;

    if (!mounted) return;
    setState(() {
      items = detail;
      transaksi = trx;
      _isLoading = false;
    });
  }

  Future<void> printNota(int transaksiId) async {
    final detailItems = items;
    final trx = transaksi;

    if (trx == null) return;

    final connected = await _printerService.isConnected();
    if (!connected) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Printer belum terhubung'),
          action: SnackBarAction(
            label: 'Pilih Printer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    final paid = (trx['paid_amount'] ?? 0) as int;
    final method = (trx['payment_method'] ?? '-').toString();
    final total = (trx['total'] ?? 0) as int;
    final createdAt = DateTime.parse(trx['created_at'].toString());
    final printed = await _printerService.printTransactionReceipt(
      transaksiId: transaksiId,
      dateTime: createdAt,
      method: method,
      total: total,
      paid: paid,
      items: detailItems,
    );

    if (!printed) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Struk berhasil dikirim ke printer')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (transaksi == null) {
      return const Scaffold(
        body: Center(child: Text('Detail transaksi tidak ditemukan')),
      );
    }

    final trx = transaksi!;
    final paid = (trx['paid_amount'] ?? 0) as int;
    final method = (trx['payment_method'] ?? '-').toString();
    final createdAt = DateTime.parse(trx['created_at'].toString());
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(createdAt);
    final change = paid - widget.total;

    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryBlue,
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: 'Cetak Struk',
            onPressed: () => printNota(widget.transaksiId),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(formattedDate, method),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _summaryCard(
                        label: 'Total',
                        value: 'Rp ${_currencyFormat.format(widget.total)}',
                        icon: Icons.payments_rounded,
                        color: _successGreen,
                        bgColor: const Color(0xFFF0FDF4),
                      ),
                      const SizedBox(width: 10),
                      _summaryCard(
                        label: 'Kembalian',
                        value:
                            'Rp ${_currencyFormat.format(change < 0 ? 0 : change)}',
                        icon: Icons.keyboard_return_rounded,
                        color: _primaryBlue,
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentInfo(formattedDate, method, paid),
                  const SizedBox(height: 12),
                  _buildItemsCard(),
                  const SizedBox(height: 12),
                  _buildReceiptCard(_receiptText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String formattedDate, String method) {
    final pm = method.toLowerCase();
    final methodColor =
        pm.contains('cash')
            ? _successGreen
            : pm.contains('transfer') || pm.contains('qris')
            ? _primaryBlue
            : const Color(0xFF7C3AED);

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
                  'Transaksi',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${widget.transaksiId} - $formattedDate',
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              method,
              style: TextStyle(
                color: methodColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(String formattedDate, String method, int paid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _infoRow('Tanggal', formattedDate),
          const SizedBox(height: 8),
          _infoRow('Metode', method),
          const SizedBox(height: 8),
          _infoRow('Uang Dibayar', 'Rp ${_currencyFormat.format(paid)}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Transaksi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final qty = (item['qty'] ?? 0) as int;
            final price = (item['price'] ?? 0) as int;
            final subtotal = qty * price;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$qty x Rp ${_currencyFormat.format(price)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${_currencyFormat.format(subtotal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (index < items.length - 1) ...[
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade100, height: 1),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(String receiptText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview Struk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: _buildThermalPreview(receiptText),
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
